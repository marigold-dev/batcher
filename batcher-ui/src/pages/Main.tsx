import React, { useState, useEffect } from 'react';
import Exchange from '@/components/Exchange';
import About from '@/components/About';
import Volume from '@/components/Volume';
import BatcherInfo from '@/components/BatcherInfo';
import BatcherAction from '@/components/BatcherAction';
import {
  ContentType,
  token,
  BatcherStatus,
  Volumes,
  swap,
  tokens,
} from '@/extra_utils/types';
import { ContractsService, MichelineFormat } from '@dipdup/tzkt-api';
import { Space, Col, Row, Drawer, Radio, } from 'antd';
import { CiTwoTone, DoubleRightOutlined } from '@ant-design/icons';
import type {  RadioChangeEvent } from 'antd';
import { useModel } from 'umi';
import {
  getEmptyVolumes,
  setTokenAmount,
  setSocketTokenAmount,
  scaleStringAmountDown,
} from '@/extra_utils/utils';
import { connection, init } from '@/extra_utils/webSocketUtils';
import { scaleAmountUp, zeroHoldings } from '@/extra_utils/utils';
import Holdings from '@/components/Holdings';
import { TezosToolkit } from '@taquito/taquito';

const Welcome: React.FC = () => {

  const [Tezos] = useState<TezosToolkit>(new TezosToolkit(REACT_APP_TEZOS_NODE_URI));
  const [content, setContent] = useState<ContentType>(ContentType.SWAP);
  const [tokenMap, setTokenMap] = useState<Map<string,swap>>(new Map());
  const [ratesBigMapId, setRatesBigMapId] = useState<number>(0);
  const [userBatchOrderTypesBigMapId, setUserBatchOrderTypesBigMapId] = useState<number>(0);
  const [batchesBigMapId, setBatchesBigMapId] = useState<number>(0);
  const [contractAddress] = useState<string>(REACT_APP_BATCHER_CONTRACT_HASH);
  const chain_api_url = REACT_APP_TZKT_URI_API;
  const contractsService = new ContractsService({
    baseUrl: chain_api_url,
    version: '',
    withCredentials: false,
  });
  const [bigMapsByIdUri] = useState<string>('' + chain_api_url + '/v1/bigmaps/');
  const [inversion, setInversion] = useState(true);
  const { initialState } = useModel('@@initialState');
  const { userAddress } = initialState;

  const [buyToken, setBuyToken] = useState<token>({
        token_id: 0,
        name: 'tzBTC',
        address: undefined,
        decimals: 8,
        standard: 'FA1.2 token',
      });
  const [sellToken, setSellToken] = useState<token>({
        token_id: 0,
        name: 'USDT',
        address: undefined,
        decimals: 6,
        standard: 'FA2 token',
      });
  const [tokenPair, setTokenPair] = useState<string>(buyToken.name + '/' + sellToken.name);
  const [buyBalance, setBuyBalance] = useState(0);
  const [sellBalance, setSellBalance] = useState(0);

  const [rate, setRate] = useState(0);
  const [status, setStatus] = useState<string>(BatcherStatus.NONE);
  const [openTime, setOpenTime] = useState<string>(null);
  const [clearedHoldings, setClearedHoldings] = useState<Map<string, number>>(new Map<string, number>());
  const [openHoldings, setOpenHoldings] = useState<Map<string, number>>(new Map<string, number>());
  const [feeInMutez, setFeeInMutez] = useState<number>(0);
  const [volumes, setVolumes] = useState<Volumes>(getEmptyVolumes());
  const [updateAll, setUpdateAll] = useState<boolean>(false);

  const pullStorage = async () => {
    const storage = await contractsService.getStorage({
      address: contractAddress,
      level: 0,
      path: null,
    });
    console.log('##storage', storage);
    return storage;
  };

  const scaleVolumeDown = (vols: Volumes) => {
    return {
      buy_minus_volume: scaleStringAmountDown(vols.buy_minus_volume, buyToken.decimals),
      buy_exact_volume: scaleStringAmountDown(vols.buy_exact_volume, buyToken.decimals),
      buy_plus_volume: scaleStringAmountDown(vols.buy_plus_volume, buyToken.decimals),
      sell_minus_volume: scaleStringAmountDown(vols.sell_minus_volume, sellToken.decimals),
      sell_exact_volume: scaleStringAmountDown(vols.sell_exact_volume, sellToken.decimals),
      sell_plus_volume: scaleStringAmountDown(vols.sell_plus_volume, sellToken.decimals),
    };
  };

  const setStatusFromBatch = (jsonData:any) => {
    try {
        const status = Object.keys(jsonData.value.status)[0];
        setStatus(status);
        if (status === BatcherStatus.OPEN) {
          setOpenTime(jsonData.value.status.open);
        }
        if (status === BatcherStatus.CLOSED) {
          setStatus(BatcherStatus.CLOSED);
        }
    } catch (error) {

      console.error('Unable to set status', error);
    }
  }
  const getCurrentVolume = async (storage: any) => {
    try {
     const currentBatchIndices = storage.batch_set.current_batch_indices;
     const index_map = new Map(Object.keys(currentBatchIndices).map(k => [k, currentBatchIndices[k] as number]));
     const currentBatchNumber = index_map.get(tokenPair);
     console.log('current_batch_number', currentBatchNumber);

      if (currentBatchNumber === 0) {
        setStatus(BatcherStatus.NONE);
        const vols: Volumes = getEmptyVolumes();
        setVolumes(vols);
      } else {
        const currentBatchURI =
          bigMapsByIdUri + batchesBigMapId + '/keys/' + currentBatchNumber;
        console.log('######Volumes - URI', currentBatchURI);
        const data = await fetch(currentBatchURI, {
          method: 'GET',
        });
        if(data.ok && data.status !== 204) {
        const jsonData = await data.json();
        setStatusFromBatch(jsonData);
        // eslint-disable-next-line @typescript-eslint/no-shadow
        const scaledVolumes = scaleVolumeDown(jsonData.value.volumes);
        setVolumes(scaledVolumes);
        } else {
         console.info("Response from current batch api was no ok", data);
        }
      }
    } catch (error) {
      console.error('Unable to get current volume', error);
    }
  };

  // eslint-disable-next-line @typescript-eslint/no-shadow
  const setFee = async (storage: any) => {
    try{
    const fee  = storage.fee_in_mutez;
    setFeeInMutez(fee);
    } catch (error) {
      console.error('Unable to set fee', error);
    }
  };


   const updateSwapMap = async (storage: any) => {
   try{
    const valid_swaps = storage.valid_swaps;
    console.info('Valid Swaps', valid_swaps);
    const swap_map = new Map(Object.keys(valid_swaps).filter(k => !valid_swaps[k].is_disabled_for_desposits).map(k => [k, valid_swaps[k]]));
    setTokenMap(swap_map);
    } catch (error) {
      console.error('Unable to update swap map', error);
    }
   };

  const getOriginalDepositAmounts = (side:any, initialBuySideAmount:number, initialSellSideAmount:number, depositValue:number) => {
    if (Object.keys(side).at(0) === "buy"){
        initialBuySideAmount += Math.floor(depositValue) / 10 ** buyToken.decimals;
    } else if (Object.keys(side).at(0) === "sell") {
        initialSellSideAmount += Math.floor(depositValue) / 10 ** sellToken.decimals;
    } else {
    console.error("Couldn't understand which side the deposit was on");
    }
    return [initialBuySideAmount, initialSellSideAmount];

  };

  const wasInClearingForBatch = (side_obj:any, order_tolerance_obj:any, clearing_tolerance_obj:any) => {
      console.info("wasInClearingForBatch - side_obj", side_obj);
      console.info("wasInClearingForBatch - order_tolerance_obj", order_tolerance_obj);
      console.info("wasInClearingForBatch - clearing_tolerance_obj", clearing_tolerance_obj);
      const side = Object.keys(side_obj).at(0);
      const order_tolerance = Object.keys(order_tolerance_obj).at(0);
      const clearing_tolerance = Object.keys(clearing_tolerance_obj).at(0);
      console.info("wasInClearingForBatch - side", side);
      console.info("wasInClearingForBatch - order_tolerance", order_tolerance);
      console.info("wasInClearingForBatch - clearing_tolerance", clearing_tolerance);
      if (side == "buy") {
        if (clearing_tolerance === "minus") {
            if (order_tolerance === "minus"){
              return true;
            } else if (order_tolerance === "exact") {
              return false;
            } else if (order_tolerance === "plus") {
              return false;
            } else {
              console.error("Could not determine order tolerance for buy deposit");
            }
        } else if (clearing_tolerance === "exact") {
            if (order_tolerance === "minus"){
              return true;
            } else if (order_tolerance === "exact") {
              return true;
            } else if (order_tolerance === "plus") {
              return false;
            } else {
              console.error("Could not determine order tolerance for buy deposit");
            }
        } else if (clearing_tolerance === "plus") {
            if (order_tolerance === "minus"){
              return true;
            } else if (order_tolerance === "exact") {
              return true;
            } else if (order_tolerance === "plus") {
              return true;
            } else {
              console.error("Could not determine order tolerance for buy deposit");
            }
        } else {
         console.error("Unable to determine clearing tolerance for buy deposit");
        }
      } else if (side == "sell") {

        if (clearing_tolerance === "minus") {
            if (order_tolerance === "minus"){
              return true;
            } else if (order_tolerance === "exact") {
              return true;
            } else if (order_tolerance === "plus") {
              return true;
            } else {
              console.error("Could not determine order tolerance for buy deposit");
            }
        } else if (clearing_tolerance === "exact") {
            if (order_tolerance === "minus"){
              return false;
            } else if (order_tolerance === "exact") {
              return true;
            } else if (order_tolerance === "plus") {
              return true;
            } else {
              console.error("Could not determine order tolerance for buy deposit");
            }
        } else if (clearing_tolerance === "plus") {
            if (order_tolerance === "minus"){
              return false;
            } else if (order_tolerance === "exact") {
              return false;
            } else if (order_tolerance === "plus") {
              return true;
            } else {
              console.error("Could not determine order tolerance for buy deposit");
            }
        } else {
         console.error("Unable to determine clearing tolerance for buy deposit");
        }
      } else {
        console.error("Unable to determine side for holdings");
      }
  };

  const convertHoldingToPayout = (fromAmount:any, fromVolumeSubjectToClearing:any, fromClearedVolume:any, toClearedVolume:any, fromDecimals:number, toDecimals:number) => {

     const prorata = fromAmount / fromVolumeSubjectToClearing;
     const payout = toClearedVolume * prorata;
     const payoutInFromTokens = fromClearedVolume * prorata;
     const remainder = fromAmount - payoutInFromTokens;
     const scaled_payout = Math.floor(payout) / 10 ** toDecimals;
     const scaled_remainder = Math.floor(remainder) / 10 ** fromDecimals;

     return [scaled_payout, scaled_remainder];
  };




  const findTokensForBatch = (batch: any) => {

    const pair =  batch.pair
    const tokens:tokens = {
      buy_token_name : pair.name_0,
      sell_token_name : pair.name_1,

    }
    return tokens;
  };



  const calculateHoldingFromBatch = (batch: any, ubots: any, open_holdings: Map<string, number> , cleared_holdings: Map<string, number> ) => {

   const tokens = findTokensForBatch(batch);
    const depositsInBatches = ubots.value;
    const userBatchLength = depositsInBatches[batch.batch_number].length;

    if (Object.keys(batch.status)[0] !== BatcherStatus.CLEARED){

      for (let j = 0; j < userBatchLength; j++) {
        try{
        const depObject = ubots.value[batch.batch_number].at(j);
        const side = depObject.key.side;
        const value = depObject.value;
        let initialBuySideOpenAmount = open_holdings.get(tokens.buy_token_name);
        let initialSellSideOpenAmount = open_holdings.get(tokens.sell_token_name);
        const updatedValues = getOriginalDepositAmounts(side,initialBuySideOpenAmount, initialSellSideOpenAmount,value);
        initialBuySideOpenAmount += updatedValues.at(0);
        initialSellSideOpenAmount += updatedValues.at(1);
        open_holdings.set(tokens.buy_token_name,initialBuySideOpenAmount);
        open_holdings.set(tokens.sell_token_name, initialSellSideOpenAmount);
        } catch (error) {
          console.error(error);
        }
      }
    } else {

      const cleared = batch.status.cleared;
      const clearing = cleared.clearing;
      const buy_side_cleared_volume = clearing.total_cleared_volumes.buy_side_total_cleared_volume;
      const sell_side_cleared_volume = clearing.total_cleared_volumes.sell_side_total_cleared_volume;
      const buy_side_volume_subject_to_clearing = clearing.total_cleared_volumes.buy_side_volume_subject_to_clearing;
      const sell_side_volume_subject_to_clearing = clearing.total_cleared_volumes.sell_side_volume_subject_to_clearing;

      let rate_data = clearing.clearing_rate.rate;

      for (let j = 0; j < userBatchLength; j++) {
        try{
        const depObject = ubots.value[batch.batch_number].at(j);
        const side = depObject.key.side;
        const tol = depObject.key.tolerance;
        const value = depObject.value;

        if (buy_side_cleared_volume === 0 || sell_side_cleared_volume === 0 ){
        let initialBuySideAmount = cleared_holdings.get(tokens.buy_token_name);
        let initialSellSideAmount = cleared_holdings.get(tokens.sell_token_name);
        const updatedValues = getOriginalDepositAmounts(side,initialBuySideAmount, initialSellSideAmount,value);
        initialBuySideAmount += updatedValues.at(0);
        initialSellSideAmount += updatedValues.at(1);
        cleared_holdings.set(tokens.buy_token_name,initialBuySideAmount);
        cleared_holdings.set(tokens.sell_token_name, initialSellSideAmount);
        } else
        {
          const wasInClearing = wasInClearingForBatch(side, tol,clearing.clearing_tolerance);
          if (wasInClearing) {
            if (Object.keys(side).at(0) === "buy") {
               let initialBuySideAmount = cleared_holdings.get(tokens.buy_token_name);
               let initialSellSideAmount = cleared_holdings.get(tokens.sell_token_name);
               const payout = convertHoldingToPayout(value,buy_side_volume_subject_to_clearing,buy_side_cleared_volume, sell_side_cleared_volume,buyToken.decimals, sellToken.decimals);
               initialSellSideAmount += payout.at(0);
               initialBuySideAmount += payout.at(1);
               cleared_holdings.set(tokens.buy_token_name,initialBuySideAmount);
               cleared_holdings.set(tokens.sell_token_name, initialSellSideAmount);
            } else if (Object.keys(side).at(0) === "sell"){
               let initialBuySideAmount = cleared_holdings.get(tokens.buy_token_name);
               let initialSellSideAmount = cleared_holdings.get(tokens.sell_token_name);
               const payout = convertHoldingToPayout(value,sell_side_volume_subject_to_clearing, sell_side_cleared_volume, buy_side_cleared_volume, sellToken.decimals, buyToken.decimals);
               initialBuySideAmount += payout.at(0);
               initialSellSideAmount += payout.at(1);
               cleared_holdings.set(tokens.buy_token_name,initialBuySideAmount);
               cleared_holdings.set(tokens.sell_token_name, initialSellSideAmount);
            } else {
              console.error("Unable to determine side for a deposit that was in clearing");
            }
          } else {
           let initialBuySideAmount = cleared_holdings.get(tokens.buy_token_name);
           let initialSellSideAmount = cleared_holdings.get(tokens.sell_token_name);
           const updatedValues = getOriginalDepositAmounts(side,initialBuySideAmount, initialSellSideAmount,value);
           initialBuySideAmount += updatedValues.at(0);
           initialSellSideAmount += updatedValues.at(1);
           cleared_holdings.set(tokens.buy_token_name,initialBuySideAmount);
           cleared_holdings.set(tokens.sell_token_name, initialSellSideAmount);
          }
        }

        } catch (error) {
          console.error(error);
        }
      }
    }
    return [open_holdings, cleared_holdings];

  };


  const updateHoldings = async (storage: any) => {
    let oh = openHoldings;
    let ch = clearedHoldings;
    try{
    if (!userAddress) {
      return;
    }

    console.info("##open holdings", openHoldings);
    console.info("##cleared holdings", clearedHoldings);
    const userBatcherURI = bigMapsByIdUri + userBatchOrderTypesBigMapId + '/keys/' + userAddress;
    const userOrderBookData = await fetch(userBatcherURI, { method: 'GET' });
    let userBatches = null;
    try {
      userBatches = await userOrderBookData.json();
    } catch (error) {
      console.error(error);
      return;
    }

    if (Object.keys(userBatches.value).length === 0) {
      return;
    }

    for (let i = 0; i < Object.keys(userBatches.value).length; i++) {
      const batchId = Object.keys(userBatches.value).at(i);

      const batchURI = bigMapsByIdUri + storage.batch_set.batches + '/keys/' + batchId;
      const batchData = await fetch(batchURI, { method: 'GET' });
      let batch = null;
      try {
        batch = await batchData.json();
      } catch (error) {
        console.error(error);
        return;
      }

      try{
      let batch_holdings = calculateHoldingFromBatch(batch.value,userBatches, oh, ch);

    console.info("== batcher holdings " + batchId, batch_holdings);
      oh = batch_holdings[0];
      ch = batch_holdings[1];

      } catch (error) {
        console.error(error);
      }
    }
    } catch (error) {
      console.error('Unable to update holdings', error);
    }
    setOpenHoldings(oh);
    setClearedHoldings(ch);
  };






  const getBatches = async (storage: any) => {
    await getCurrentVolume(storage);
  };

   const updateTokenBalances = (tokenBalances: any) => {
       try{
     console.log('tokenbalances', tokenBalances);
      setSocketTokenAmount(
         tokenBalances,
         userAddress,
         buyToken,
         setBuyBalance,
       );
     console.log('updateBuyBalance', buyBalance);

       setSocketTokenAmount(
         tokenBalances,
         userAddress,
         sellToken,
         setSellBalance,
       );
     console.log('updateSellBalance', sellBalance);

     } catch (error) {
       console.error('Unable to update token balances', error);
     }
   };


  const updateRate= (bigmaps: any) => {
     try{
    console.log('bigmaps', bigmaps);
      const numerator = bigmaps.content.value.rate.p;
      const denominator = bigmaps.content.value.rate.q;

      const scaledPow = buyToken.decimals - sellToken.decimals;
      const scaledRate = scaleAmountUp(numerator / denominator, scaledPow);
      setRate(scaledRate);
    } catch (error) {
      console.error('Unable to update rate', error);
    }

  };



  const updateTokenDetails = async (storage: any) => {
     try{
      setTokenPair(buyToken.name + '/' +  sellToken.name);

      const valid_tokens = storage.valid_tokens;
      const token_map = new Map(Object.keys(valid_tokens).map(k => [k, valid_tokens[k]]));
      const buyTokenData = token_map.get(buyToken.name);
       console.log("buyTokenAddress",buyToken.address);
      const sellTokenData = token_map.get(sellToken.name);
       console.log("sellTokenAddress",sellToken.address);

      const bToken : token = {
        token_id: buyTokenData.token_id,
        name: buyTokenData.name,
        address: buyTokenData.address,
        decimals: buyTokenData.decimals,
        standard: buyTokenData.standard,
      };
      const sToken : token = {
        token_id: sellTokenData.token_id,
        name: sellTokenData.name,
        address: sellTokenData.address,
        decimals: sellTokenData.decimals,
        standard: sellTokenData.standard,
      };


      if(buyToken != bToken)
        setBuyToken(bToken);

      if(sellToken != sToken)
        setSellToken(sToken);

    } catch (error) {
      console.error('Unable to update token details', error);
    }
  };

  const setOraclePrice = async (rates: any) => {
    if (rates.length != 0) {
      // eslint-disable-next-line @typescript-eslint/no-shadow
      console.info("rates",rates);
      console.info("tokenPair",tokenPair);
      const rate = rates.filter((r) => r.key == tokenPair)[0].value;
      const numerator = rate.rate.p;
      const denominator = rate.rate.q;
      const scaledPow = buyToken.decimals - sellToken.decimals;
      const scaledRate = scaleAmountUp(numerator / denominator, scaledPow);
      setRate(scaledRate);
    }
  };

  const getOraclePrice = async () => {
    await contractsService.getBigMapByNameKeys({
      address: REACT_APP_BATCHER_CONTRACT_HASH,
      name: 'rates_current',
      micheline: MichelineFormat.JSON,
    }).then(r => setOraclePrice(r));
  };


  const [open, setOpen] = useState(false);
  const [swaps, setSwaps] = useState<string[]>([]);
  const showDrawer = () => {
    setOpen(true);
  };

  const onClose = () => {
    setOpen(false);
  };



  const getPairs = () => {
    const swps = [];
     console.log('swap_map', tokenMap);
     for (const keyvalue of tokenMap)  {
         console.log(keyvalue);
         swps.push(keyvalue[0]);
     }
    setSwaps(swps);
    console.log('swps', swps);
    console.log('swaps', swaps);
  };

 const changeTokenPair =  (e: RadioChangeEvent) => {
    const pair = e.target.value;
    console.log('pair changed', pair);
    setTokenPair(pair);
    const swap = tokenMap.get(pair);
    console.log('pair changed to ', swap);
    // Set Buy Token Details
    setBuyToken(swap.swap.from.token);

    // Set Sell Token Details
    setSellToken(swap.swap.to);

 };

  const generatePairs = () => {
      return (
            <>
            {
            swaps.map((swap) =>
                <React.Fragment key={swap}>
                       <Radio.Button className="batcher-nav-btn" value={swap} onChange={changeTokenPair} >{swap}</Radio.Button>
                </React.Fragment>
            )}
        </>
    );


  };


  useEffect(() => {
    getPairs();
  }, [tokenMap]);
  // eslint-disable-next-line @typescript-eslint/no-shadow
  const renderRightContent = (content: ContentType) => {
    console.log('rendering content');
    switch (content) {
      case ContentType.SWAP:
        return (
          <Exchange
            userAddress={userAddress}
            buyBalance={buyBalance}
            sellBalance={sellBalance}
            inversion={inversion}
            setInversion={setInversion}
            tezos={Tezos}
            fee_in_mutez={feeInMutez}
            buyToken={buyToken}
            sellToken={sellToken}
            showDrawer={showDrawer}
            updateAll={updateAll}
            setUpdateAll={setUpdateAll}
          />
        );
      case ContentType.VOLUME:
        return <Volume volumes={volumes} />;
      case ContentType.REDEEM_HOLDING:
        return (
          <Holdings
            tezos={Tezos}
            userAddress={userAddress}
            contractAddress={contractAddress}
            openHoldings={openHoldings}
            clearedHoldings={clearedHoldings}
            setOpenHoldings={setOpenHoldings}
            setClearedHoldings={setClearedHoldings}
            updateAll={updateAll}
            setUpdateAll={setUpdateAll}
          />
        );
      case ContentType.ABOUT:
        return <About />;
      default:
        return (
          <Exchange
            userAddress={userAddress}
            buyBalance={buyBalance}
            sellBalance={sellBalance}
            inversion={inversion}
            setInversion={setInversion}
            tezos={Tezos}
            fee_in_mutez={feeInMutez}
            buyToken={buyToken}
            sellToken={sellToken}
            showDrawer={showDrawer}
            updateAll={updateAll}
            setUpdateAll={setUpdateAll}
          />
        );
    }
  };

  const updateBigMapIds = (storage: any) => {
    try{
     setRatesBigMapId(storage.rates_current);
     setUserBatchOrderTypesBigMapId(storage.user_batch_ordertypes);
     setBatchesBigMapId(storage.batch_set.batches);
    } catch (error) {
      console.error('Unable to update bigmap ids', error);
    }

  };

  const getTokenBalance = async () => {
    try{
      let usrAddr = userAddress
      if(userAddress === null){
        if(initialState.userAddress !== null){
          usrAddr = initialState.userAddress;
          setUserAddress(usrAddr);
        }
      }

      if(usrAddr === null){
        setBuyBalance(0);
        setSellBalance(0);
      } else {

      console.log('getTokenBalance-userAddress',usrAddr);
      const balanceURI = REACT_APP_TZKT_URI_API + '/v1/tokens/balances?account=' + usrAddr;
      console.log('getTokenBalance-balanceURI',balanceURI);
      const data = await fetch(balanceURI, { method: 'GET' });
      await data.json().then(balance => {
      if (Array.isArray(balance)) {
        setTokenAmount(balance, buyBalance, buyToken.address, buyToken.decimals, setBuyBalance);
        setTokenAmount(balance, sellBalance, sellToken.address, sellToken.decimals, setSellBalance);
      }
      });
      }
    } catch (error) {
      console.error('getTokenBalance-error',error);
      if(!userAddress) {
      setBuyBalance(0);
      setSellBalance(0);
      } else {
      setBuyBalance(-1);
      setSellBalance(-1);
      }
    }
  };

  const updateFromStorage = async (storage: any) => {
    updateBigMapIds(storage);
    zeroHoldings(storage, setOpenHoldings,setClearedHoldings);
    await updateTokenDetails(storage);
    await getBatches(storage);
    await updateSwapMap(storage);
    await setFee(storage);
    await getOraclePrice();
    await getTokenBalance();
    await updateHoldings(storage);
    await getCurrentVolume(storage);

  };


  const handleWebsocket = () => {
    connection.on('token_balances', (msg: any) => {
      if (!msg.data) return;
      updateTokenBalances(msg.data);
    });

    // This is the place handling operations and storages
    connection.on('operations', (msg: any) => {
      if (!msg.data) return;
      if (!msg.data[0].storage) return;
      console.info("#######WS###### - operations", msg.data[0].storage)
      updateFromStorage(msg.data[0].storage).then(r => console.log(r));
    });

    connection.on('bigmaps', (msg: any) => {
      if (!msg.data) return;

      const bigmapsdata = msg.data[0];
      console.info("#######WS###### - bigmap", msg.data[0])

      if(bigmapsdata.bigmap == ratesBigMapId){
        updateRate(msg.data[0]);
      }
    });

   if (userAddress) {
    init(userAddress).then(r => console.log(r));
    }

  };

  const refreshStorage = async () => {
    pullStorage().then(s => updateFromStorage(s))
  };

  useEffect(() => {
    refreshStorage().then(r => console.log(r));
    handleWebsocket();
  }, []);

  useEffect(() => {
    if(initialState?.wallet !== null){
      Tezos.setWalletProvider(initialState.wallet);
    }
  }, []);
  useEffect(() => {
    refreshStorage().then(r => console.log(r));
  }, [buyToken.address, sellToken.address, updateAll]);

  useEffect(() => {
    console.log("User address changed - refreshing from storage")
    refreshStorage().then(r => console.log(r));
  }, [userAddress]);


  return (
    <div>
      <BatcherInfo
        userAddress={userAddress}
        tokenPair={tokenPair}
        buyBalance={buyBalance}
        sellBalance={sellBalance}
        buyTokenName={buyToken.name}
        sellTokenName={sellToken.name}
        inversion={inversion}
        rate={rate}
        status={status}
        openTime={openTime}
        updateAll={updateAll}
        setUpdateAll={setUpdateAll}
      />
      <BatcherAction
        content={content}
        setContent={setContent}
        />
      <div>
        <Row className="batcher-content">
          <Col lg={3} />
          <Col className="batcher-content-outer" xs={24} lg={18}>
            <Row>
        <Drawer
         title="Pairs"
         placement="right"
         closable={true}
         onClose={onClose}
         open={open}
         getContainer={false}
         style={{ position: 'absolute' }}
         width={180}
         closeIcon={<DoubleRightOutlined />}
        >
        <Radio.Group defaultValue={tokenPair} buttonStyle="solid" size="large">
         <Space direction="vertical">
          {
            generatePairs()
          }
          </Space>
        </Radio.Group>
        </Drawer>
              <Col lg={3} />
              <Col xs={24} lg={18} className="pd-25">
                {renderRightContent(content)}
              </Col>
            </Row>
          </Col>
        </Row>
      </div>
    </div>
  );
};

export default Welcome;
