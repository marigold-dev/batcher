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
  BUY,
  SELL,
  MINUS,
  EXACT,
  PLUS,
  CLEARED,
  Volumes,
  swap,
} from '@/extra_utils/types';
import { TezosToolkit } from '@taquito/taquito';
import { ContractsService, MichelineFormat } from '@dipdup/tzkt-api';
import { Input, Button, Space, Typography, Col, Row, message, Form, Drawer, Radio, } from 'antd';
import { Icon, DoubleRightOutlined, DollarOutlined } from '@ant-design/icons';
import type {  RadioChangeEvent } from 'antd';
import { useModel } from 'umi';
import {
  getEmptyVolumes,
  getNetworkType,
  setTokenAmount,
  setSocketTokenAmount,
  scaleStringAmountDown,
} from '@/extra_utils/utils';
import { connection, init } from '@/extra_utils/webSocketUtils';
import { scaleAmountUp } from '@/extra_utils/utils';
import Holdings from '@/components/Holdings';
import { BeaconWallet } from '@taquito/beacon-wallet';

const Welcome: React.FC = () => {


  const [content, setContent] = useState<ContentType>(ContentType.SWAP);
  const [Tezos] = useState<TezosToolkit>(new TezosToolkit(REACT_APP_TEZOS_NODE_URI));
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
  const { initialState, setInitialState } = useModel('@@initialState');
  const { wallet, storedUserAddress } = initialState;
  const [userAddress, setUsrAddress] = useState<string>(undefined);

  const [buyToken, setBuyToken] = useState<token>({
        name: 'tzBTC',
        address: undefined,
        decimals: 8,
        standard: 'FA1.2 token',
      });
  const [sellToken, setSellToken] = useState<token>({
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
  const [buySideAmount, setBuySideAmount] = useState<number>(0);
  const [sellSideAmount, setSellSideAmount] = useState<number>(0);
  const [feeInMutez, setFeeInMutez] = useState<number>(0);
  const [volumes, setVolumes] = useState<Volumes>(getEmptyVolumes());

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
        const data = await fetch(currentBatchURI, {
          method: 'GET',
        });
        const jsonData = await data.json();
        // eslint-disable-next-line @typescript-eslint/no-shadow
        const status = Object.keys(jsonData.value.status)[0];
        setStatus(status);
        if (status === BatcherStatus.OPEN) {
          setOpenTime(jsonData.value.status.open);
        }
        const scaledVolumes = scaleVolumeDown(jsonData.value.volumes);
        setVolumes(scaledVolumes);
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
    if (side === BUY){
        initialBuySideAmount += Math.floor(depositValue) / 10 ** buyToken.decimals;
    } else if (side === SELL) {
        initialSellSideAmount += Math.floor(depositValue) / 10 ** sellToken.decimals;
    } else {
    console.error("Couldn't understand which side the deposit was on");
    }
    return [initialBuySideAmount, initialSellSideAmount];

  }; 

  const wasInClearingForBatch = (side_obj:any, order_tolerance_obj:any, clearing_tolerance_obj:any) => {
      const side = Object.keys(side_obj).at(0);
      const order_tolerance = Object.keys(order_tolerance_obj).at(0);
      const clearing_tolerance = Object.keys(clearing_tolerance_obj).at(0);
      console.info("wasInClearingForBatch - side", side);
      console.info("wasInClearingForBatch - order_tolerance", order_tolerance);
      console.info("wasInClearingForBatch - clearing_tolerance", clearing_tolerance);
      if (side === "buy") {
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
      } else if (side === "sell") {

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

     console.log("convertHoldingToPayout - fromAmount", fromAmount); 
     console.log("convertHoldingToPayout - fromVolumeSubjectToClearing", fromVolumeSubjectToClearing); 
     console.log("convertHoldingToPayout - prorata", prorata); 
     console.log("convertHoldingToPayout - prorata", prorata); 
     console.log("convertHoldingToPayout - payout", payout); 
     console.log("convertHoldingToPayout - payoutInFromTokens", payoutInFromTokens); 
     console.log("convertHoldingToPayout - remainder", remainder); 
     console.log("convertHoldingToPayout - scaled_payout", scaled_payout); 
     console.log("convertHoldingToPayout - scaled_remainder", scaled_remainder); 
     return [scaled_payout, scaled_remainder];
  };


  const calculateHolidingFromBatch = (batch: any, ubots: any, userAddress: any) => {
    let initialBuySideAmount = 0;
    let initialSellSideAmount = 0;
      
    console.log("batch", batch); 

      const cleared = batch.status.cleared;
      console.log("cleared", cleared); 
      const clearing = cleared.clearing;
      console.log("clearing", clearing); 
      const volumes = batch.volumes;
      const buy_side_cleared_volume = clearing.total_cleared_volumes.buy_side_total_cleared_volume;
      const sell_side_cleared_volume = clearing.total_cleared_volumes.sell_side_total_cleared_volume;
      const buy_side_volume_subject_to_clearing = clearing.total_cleared_volumes.buy_side_volume_subject_to_clearing;
      const sell_side_volume_subject_to_clearing = clearing.total_cleared_volumes.sell_side_volume_subject_to_clearing;

      let clearingRate = 0;
      let rate_data = clearing.clearing_rate.rate;
      console.log("rate_data", rate_data); 
      const originalClearingRate =
        parseInt(rate_data.p) /
        parseInt(rate_data.q);
      //const total_buy_side_volume = Object.keys(batch.status)[0];

      console.log("ubots", ubots); 
      console.log("batch_number", batch.batch_number); 
      const depositsInBatches = ubots.value;
      console.log("depositsInBatches", depositsInBatches); 

      const userBatchLength = depositsInBatches[batch.batch_number].length; 

      for (let j = 0; j < userBatchLength; j++) {
        try{
        const depObject = ubots.value[batch.batch_number].at(j);
        const side = depObject.key.side;
        const tol = depObject.key.tolerance;
        const value = depObject.value;
        console.log("Deposit Side- " + j, side); 
        console.log("Deposit Tolerance- " + j, tol); 
        console.log("Deposit Value- " + j, value); 
         
        if (buy_side_cleared_volume === 0 || sell_side_cleared_volume === 0 ){
           const updatedValues = getOriginalDepositAmounts(side,initialBuySideAmount, initialSellSideAmount,value);
           initialBuySideAmount += updatedValues.at(0);
           initialSellSideAmount += updatedValues.at(1);
        } else
        {
          const wasInClearing = wasInClearingForBatch(side, tol,clearing.clearing_tolerance);
          if (wasInClearing) {
            if (Object.keys(side).at(0) === "buy") {
               const payout = convertHoldingToPayout(value,buy_side_volume_subject_to_clearing,buy_side_cleared_volume, sell_side_cleared_volume,buyToken.decimals, sellToken.decimals);   
               initialSellSideAmount += payout.at(0);
               initialBuySideAmount += payout.at(1);
               console.info("Deposit payout",payout);
            } else if (Object.keys(side).at(0) === "sell"){
               const payout = convertHoldingToPayout(value,sell_side_volume_subject_to_clearing, sell_side_cleared_volume, buy_side_cleared_volume, sellToken.decimals, buyToken.decimals);   
               initialBuySideAmount += payout.at(0);
               initialSellSideAmount += payout.at(1);
               console.info("Deposit payout",payout);
            } else {
              console.error("Unable to determine side for deposit");
            }
            console.info("order was in clearing");
          } else {
           const updatedValues = getOriginalDepositAmounts(side,initialBuySideAmount, initialSellSideAmount,value);
           initialBuySideAmount += updatedValues.at(0);
           initialSellSideAmount += updatedValues.at(1);
          } 
        }

        } catch (error) {
          console.error(error);
        }
      }
    return [initialBuySideAmount, initialSellSideAmount];

  };

  const updateHoldings = async (storage: any) => {
    console.log("Updating holdings")
    try{
    if (!userAddress) {

      console.log("No user address - won't update holdings")
      setSellSideAmount(0);
      setBuySideAmount(0);
      return;
    }

    const userBatcherURI = bigMapsByIdUri + userBatchOrderTypesBigMapId + '/keys/' + userAddress;
    console.log("userBatcherURI", userBatcherURI);
    const userOrderBookData = await fetch(userBatcherURI, { method: 'GET' });
    let userBatches = null;

    try {
      userBatches = await userOrderBookData.json();
      console.log("userBatches", userBatches);
    } catch (error) {
      console.error(error);
      return;
    }

      console.info("User batches found", userBatches.value);
      console.info("User batches length", Object.keys(userBatches.value).length);
    if (Object.keys(userBatches.value).length === 0) {
      return;
    }

    let initialBuySideAmount = 0;
    let initialSellSideAmount = 0;

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

      if (Object.keys(batch.value.status)[0] !== CLEARED) continue;
      
      try{
        
      let batch_holdings = calculateHolidingFromBatch(batch.value,userBatches, userAddress); 

      initialBuySideAmount += batch_holdings[0];
      initialSellSideAmount += batch_holdings[1];
      
      } catch (error) {
        console.error(error);
      }
    }

    setSellSideAmount(initialSellSideAmount);
    setBuySideAmount(initialBuySideAmount);
    } catch (error) {
      console.error('Unable to update holdings', error);
    }


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
        name: buyTokenData.name,
        address: buyTokenData.address,
        decimals: buyTokenData.decimals,
        standard: buyTokenData.standard,
      };
      const sToken : token = {
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

  const persistWallet = () => {
    if (!userAddress) {
      // eslint-disable-next-line @typescript-eslint/no-shadow
      const wallet = new BeaconWallet({
        name: 'batcher',
        preferredNetwork: getNetworkType(),
      });
      Tezos.setWalletProvider(wallet);
      setInitialState({...initialState, wallet: wallet, storedUserAddress: userAddress}).then(r => console.log(r));
    } else {
      Tezos.setWalletProvider(wallet);
    }
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
          />
        );
      case ContentType.VOLUME:
        return <Volume volumes={volumes} buyToken={buyToken} sellToken={sellToken} />;
      case ContentType.REDEEM_HOLDING:
        return (
          <Holdings
            tezos={Tezos}
            userAddress={userAddress}
            contractAddress={contractAddress}
            buyToken={buyToken}
            sellToken={sellToken}
            buyTokenHolding={buySideAmount}
            sellTokenHolding={sellSideAmount}
            setBuySideAmount={setBuySideAmount}
            setSellSideAmount={setSellSideAmount}
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
      console.log('getTokenBalance-userAddress',userAddress);
      const balanceURI = REACT_APP_TZKT_URI_API + '/v1/tokens/balances?account=' + userAddress;
      console.log('getTokenBalance-balanceURI',balanceURI);
      const data = await fetch(balanceURI, { method: 'GET' });
      await data.json().then(balance => {
      if (Array.isArray(balance)) {
        setTokenAmount(balance, buyBalance, buyToken.address, buyToken.decimals, setBuyBalance);
        setTokenAmount(balance, sellBalance, sellToken.address, sellToken.decimals, setSellBalance);
      }
      });
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
    await updateTokenDetails(storage);
    await getBatches(storage);
    await updateSwapMap(storage);
    await setFee(storage);
    await getOraclePrice();
    await getTokenBalance();
    await updateHoldings(storage);
    await getCurrentVolume(storage);
    persistWallet();

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
      updateFromStorage(msg.data[0].storage).then(r => console.log(r));
    });

    connection.on('bigmaps', (msg: any) => {
      if (!msg.data) return;

      const bigmapsdata = msg.data[0];

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
    refreshStorage().then(r => console.log(r));
  }, [buyToken.address, sellToken.address]);

  useEffect(() => {
    console.log("User address changed - refreshing from storage")
    refreshStorage().then(r => console.log(r));
  }, [userAddress]);

  useEffect(() => {
     if(userAddress != storedUserAddress)
        setUsrAddress(storedUserAddress);
  }, [storedUserAddress]);


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
      />
      <BatcherAction
        setContent={setContent}
        tokenMap={tokenMap}
        setBuyToken={setBuyToken}
        setSellToken={setSellToken}
        tokenPair={tokenPair}
        setTokenPair={setTokenPair}
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
