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
  MINUS,
  EXACT,
  CLEARED,
  Volumes,
  swap,
  MainProps
} from '@/extra_utils/types';
import { TezosToolkit } from '@taquito/taquito';
import { ContractsService, MichelineFormat } from '@dipdup/tzkt-api';
import { Col, Row } from 'antd';
import { useModel } from 'umi';
import {
  getEmptyVolumes,
  getNetworkType,
  getTokenAmount,
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
  const [userAddress, setUserAddress] = useState<string>('');

  const [buyToken, setBuyToken] = useState<token>({
        name: 'tzBTC',
        address: '',
        decimals: 8,
        standard: 'FA1.2 token',
      });
  const [sellToken, setSellToken] = useState<token>({
        name: 'USDT',
        address: '',
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
  const [volumes, setVolumes] = useState<Volumes>();

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
        const scaledVolumes: Volumes = scaleVolumeDown(jsonData.value.volumes);
        setVolumes(scaledVolumes);
      }
    } catch (error) {
      console.log('Unable to get current volume', error);
    }
  };

  // eslint-disable-next-line @typescript-eslint/no-shadow
  const setFee = async (storage: any) => {
    try{
    console.log('storage', storage);
    const fee  = storage.fee_in_mutez;
    setFeeInMutez(fee);
    } catch (error) {
      console.log('Unable to set fee', error);
    }
  };


   const updateSwapMap = async (storage: any) => {
   try{
    console.log('storage', storage);
    const valid_swaps = storage.valid_swaps;
    const swap_map = new Map(Object.keys(valid_swaps).map(k => [k, valid_swaps[k]]));
    console.log('swap_map', swap_map);
    setTokenMap(swap_map);
    } catch (error) {
      console.log('Unable to update swap map', error);
    }
   };

  const updateHoldings = async (storage: any) => {
    try{
    if (!userAddress) {
      console.log('updateHoldings-no-address');
      setSellSideAmount(0);
      setBuySideAmount(0);
      return;
    }

    console.log('storage', storage);
    const userBatcherURI = bigMapsByIdUri + userBatchOrderTypesBigMapId + '/keys/' + userAddress;
    const userOrderBookData = await fetch(userBatcherURI, { method: 'GET' });
    let userBatches = null;

    try {
      userBatches = await userOrderBookData.json();
    } catch (error) {
      console.error(error);
      return;
    }

    if (Object.keys(userBatches.value).length == 0) {
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

      const clearingKey = Object.keys(batch.value.status.cleared.clearing.clearing_tolerance)[0];
      let clearingRate = 0;
      let clearing = 0;

      const originalClearingRate =
        parseInt(batch.value.status.cleared.rate.rate.p) /
        parseInt(batch.value.status.cleared.rate.rate.q);
      if (clearingKey === MINUS) {
        clearingRate = originalClearingRate / 1.0001;
        clearing = batch.value.status.cleared.clearing.clearing_volumes.minus;
      } else if (clearingKey === EXACT) {
        clearingRate = originalClearingRate;
        clearing = batch.value.status.cleared.clearing.clearing_volumes.exact;
      } else {
        clearingRate = originalClearingRate * 1.0001;
        clearing = batch.value.status.cleared.clearing.clearing_volumes.plus;
      }

      const buySideActualVolume = parseInt(
        batch.value.status.cleared.clearing.prorata_equivalence.buy_side_actual_volume,
      );
      const sellSideActualVolume = parseInt(
        batch.value.status.cleared.clearing.prorata_equivalence.sell_side_actual_volume,
      );
      const userBatchLength = userBatches.value[batchId].length;

      for (let j = 0; j < userBatchLength; j++) {
        if (Object.keys(userBatches.value[batchId].at(j).key.side)[0] === BUY) {
          const depositedBuySideAmount = parseInt(userBatches.value[batchId].at(j).value);
          const unconvertedBuySideAmount =
            depositedBuySideAmount - (depositedBuySideAmount / buySideActualVolume) * clearing;
          const unconvertedSellSideAmount =
            (depositedBuySideAmount / buySideActualVolume) * clearing * clearingRate;

          initialBuySideAmount += Math.floor(unconvertedBuySideAmount) / 10 ** buyToken.decimals;
          initialSellSideAmount += Math.floor(unconvertedSellSideAmount) / 10 ** sellToken.decimals;
        } else {
          const depositedSellSideAmount = parseInt(userBatches.value[batchId].at(j).value);
          const unconvertedBuySideAmount =
            (depositedSellSideAmount / sellSideActualVolume) * clearing;
          const unconvertedSellSideAmount =
            depositedSellSideAmount -
            (depositedSellSideAmount / sellSideActualVolume) * clearing * clearingRate;

          initialBuySideAmount += Math.floor(unconvertedBuySideAmount) / 10 ** buyToken.decimals;
          initialSellSideAmount += Math.floor(unconvertedSellSideAmount) / 10 ** sellToken.decimals;
        }
      }
    }

    setSellSideAmount(initialSellSideAmount);
    setBuySideAmount(initialBuySideAmount);
    } catch (error) {
      console.log('Unable to update holdings', error);
    }
  };


  const getBatches = async (storage: any) => {
    await getCurrentVolume(storage);
  };

  // const updateTokenBalances = (tokenBalances: any) => {
  //     try{
  //   console.log('tokenbalances', tokenBalances);
  //   console.log('buyBalance', buyBalance);
  //   console.log('buyTokenAddress', buyTokenAddress);
  //     const updatedBuyBalance = getSocketTokenAmount(
  //       tokenBalances,
  //       userAddress,
  //       buyBalance,
  //       buyTokenAddress,
  //     );
  //     if (updatedBuyBalance !== 0) {
  //       setBuyBalance({
  //         ...buyBalance,
  //         balance: updatedBuyBalance,
  //       });
  //     }
  //
  //     const updatedSellBalance = getSocketTokenAmount(
  //       tokenBalances,
  //       userAddress,
  //       sellBalance,
  //       sellTokenAddress,
  //     );
  //     if (updatedSellBalance !== 0) {
  //       setSellBalance({
  //         ...sellBalance,
  //         balance: updatedSellBalance,
  //       });
  //     }
  //
  //   } catch (error) {
  //     console.log('Unable to update token balances', error);
  //   }
  // };
  //

  const updateRate= (bigmaps: any) => {
     try{
    console.log('bigmaps', bigmaps);
      const numerator = bigmaps.content.value.rate.p;
      const denominator = bigmaps.content.value.rate.q;

      const scaledPow = buyToken.decimals - sellToken.decimals;
      const scaledRate = scaleAmountUp(numerator / denominator, scaledPow);
      setRate(scaledRate);
    } catch (error) {
      console.log('Unable to update rate', error);
    }

  };



  const updateTokenDetails = async (storage: any) => {
     try{
      setTokenPair(buyToken.name + '/' +  sellToken.name);

      const valid_tokens = storage.valid_tokens;
      const token_map = new Map(Object.keys(valid_tokens).map(k => [k, valid_tokens[k]]));

      const buyTokenData = token_map.get(buyToken.name);
      console.log("buyTokenData",buyTokenData);
       console.log("buyTokenAddress",buyToken.address);
      const sellTokenData = token_map.get(sellToken.name);
       console.log("sellTokenData",sellTokenData);
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

      console.log("bToken",bToken);
      console.log("sToken",sToken);

      setBuyToken(bToken);
      setSellToken(sToken);

     setBuyBalance(0);

     setSellBalance(0);

       console.log("bToken",bToken);
       console.log("sToken",sToken);
       console.log("##-## Buy Token",buyToken);
       console.log("##-## Sell Token",sellToken);
       console.log("##-## Buy Token Balance",buyBalance);
       console.log("##-## Sell Token Balance ",sellBalance);



    } catch (error) {
      console.log('Unable to update token details', error);
    }
  };

  const setOraclePrice = async (rates: any) => {
    if (rates.length != 0) {
      // eslint-disable-next-line @typescript-eslint/no-shadow
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
      const restoredUserAddress = localStorage.getItem('userAddress');
      // eslint-disable-next-line @typescript-eslint/no-shadow
      const wallet = new BeaconWallet({
        name: 'batcher',
        preferredNetwork: getNetworkType(),
      });
      Tezos.setWalletProvider(wallet);
      setInitialState({...initialState, wallet: wallet, userAddress: restoredUserAddress}).then(r => console.log(r));
    } else {
      Tezos.setWalletProvider(wallet);
    }
  };

  // eslint-disable-next-line @typescript-eslint/no-shadow
  const renderRightContent = (content: ContentType) => {
    console.log('rendering content');
    switch (content) {
      case ContentType.SWAP:
        return (
          <Exchange
            buyBalance={buyBalance}
            sellBalance={sellBalance}
            inversion={inversion}
            setInversion={setInversion}
            tezos={Tezos}
            fee_in_mutez={feeInMutez}
            buyToken={buyToken}
            sellToken={sellToken}
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
            buyBalance={buyBalance}
            sellBalance={sellBalance}
            inversion={inversion}
            setInversion={setInversion}
            tezos={Tezos}
            fee_in_mutez={feeInMutez}
            buyToken={buyToken}
            sellToken={sellToken}
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
      console.log('Unable to update bigmap ids', error);
    }

  };
  const getTokenBalance = async () => {
    try {
      const balanceURI = REACT_APP_TZKT_URI_API + '/v1/tokens/balances?account=' + userAddress;
      const data = await fetch(balanceURI, { method: 'GET', mode: 'no-cors' });
      const balance = await data.json();
      console.log('getTokenBalance balance', balance);
      if (Array.isArray(balance)) {
        console.log('buyBalance', buyBalance);
        console.log('sellBalance', sellBalance);
        const baseAmount = getTokenAmount(balance, buyBalance, buyToken.address);
        const quoteAmount = getTokenAmount(balance, sellBalance, sellToken.address);
        setBuyBalance(baseAmount);
        setSellBalance(quoteAmount);
      }
    } catch (error) {
      if(!userAddress) {
      setBuyBalance(0);
      setSellBalance(0);
      } else {
      console.error('getTokenBalance',error);
      setBuyBalance(-1);
      setSellBalance(-1);
      }
    }
  };

  const updateFromStorage = async (storage: any) => {
    updateBigMapIds(storage);
    await getBatches(storage);
    await updateSwapMap(storage);
    await updateTokenDetails(storage);
    await setFee(storage);
    await getOraclePrice();
    await getTokenBalance();
    await updateHoldings(storage);
    await getCurrentVolume(storage);
    persistWallet();
    // renderRightContent(content);

  };


  const handleWebsocket = () => {
    console.log('########  Handle WebSocket');
    connection.on('token_balances', (msg: any) => {
      if (!msg.data) return;
      console.log('WS:token_balances ##############################################', msg);
      if (!userAddress) return;
    //  updateTokenBalances(msg.data);
    });

    // This is the place handling operations and storages
    connection.on('operations', (msg: any) => {
      if (!msg.data) return;
      if (!msg.data[0].storage) return;
      console.log('WS:operations', msg.data[0]);
      updateFromStorage(msg.data[0].storage).then(r => console.log(r));
    });

    connection.on('bigmaps', (msg: any) => {
      console.log('WS:bigmaps', msg);
      if (!msg.data) return;

      const bigmapsdata = msg.data[0];

      if(bigmapsdata.bigmap == ratesBigMapId){
        updateRate(msg.data[0]);
      }
    });

    init(userAddress).then(r => console.log(r));
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
  }, [userAddress,buyToken.name, sellToken.name]);

  const loadUserAddress = async () => {
    
      const uadd = localStorage.getItem('storedUserAddress');
      setUserAddress(uadd);
  };

  useEffect(() => {
    loadUserAddress().then(r => console.log(r));
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
