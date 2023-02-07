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
} from '@/extra_utils/types';
import { TezosToolkit } from '@taquito/taquito';
import { ContractsService, MichelineFormat } from '@dipdup/tzkt-api';
import { Col, Row } from 'antd';
import { useModel } from 'umi';
import {
  getEmptyVolumes,
  getNetworkType,
  getSocketTokenAmount,
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
  const [buyTokenName, setBuyTokenName] = useState<string>('tzBTC');
  const [buyTokenAddress, setBuyTokenAddress] = useState<string>(REACT_APP_TZBTC_HASH);
  const [buyTokenDecimals, setBuyTokenDecimals] = useState<number>(8);
  const [buyTokenStandard, setBuyTokenStandard] = useState<string>('FA1.2 token');
  const [sellTokenName, setSellTokenName] = useState<string>('USDT');
  const [sellTokenAddress, setSellTokenAddress] = useState<string>(REACT_APP_USDT_HASH);
  const [sellTokenDecimals, setSellTokenDecimals] = useState<number>(6);
  const [sellTokenStandard, setSellTokenStandard] = useState<string>('FA2 token');
  const [tokenPair, setTokenPair] = useState<string>(buyTokenName + '/' + sellTokenName);
  const buyToken: token = {
    name: buyTokenName,
    address: buyTokenAddress,
    decimals: buyTokenDecimals,
    standard: buyTokenStandard,
  };
  const sellToken: token = {
    name: sellTokenName,
    address: sellTokenAddress,
    decimals: sellTokenDecimals,
    standard: sellTokenStandard,
  };
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
  const { wallet, userAddress } = initialState;
  const [buyBalance, setBuyBalance] = useState({
    token: buyToken,
    balance: 0,
  });

  const [sellBalance, setSellBalance] = useState({
    token: sellToken,
    balance: 0,
  });
  const [rate, setRate] = useState(0);
  const [status, setStatus] = useState<string>(BatcherStatus.NONE);
  const [openTime, setOpenTime] = useState<string>(null);
  const [buySideAmount, setBuySideAmount] = useState<number>(0);
  const [sellSideAmount, setSellSideAmount] = useState<number>(0);

  const [feeInMutez, setFeeInMutez] = useState<number>(0);

  const [volumes, setVolumes] = useState<Volumes>(getEmptyVolumes());

  const scaleVolumeDown = (volumes: any) => {
    return {
      buyMinusVolume: scaleStringAmountDown(volumes.buy_minus_volume, buyTokenDecimals),
      buyExactVolume: scaleStringAmountDown(volumes.buy_exact_volume, buyTokenDecimals),
      buyPlusVolume: scaleStringAmountDown(volumes.buy_plus_volume, buyTokenDecimals),
      sellMinusVolume: scaleStringAmountDown(volumes.sell_minus_volume, sellTokenDecimals),
      sellExactVolume: scaleStringAmountDown(volumes.sell_exact_volume, sellTokenDecimals),
      sellPlusVolume: scaleStringAmountDown(volumes.sell_plus_volume, sellTokenDecimals),
    };
  };


  const getCurrentVolume = async (storage: any) => {
    try {
     const currentBatchIndices = storage.batch_set.current_batch_indices;
     const index_map = new Map(Object.keys(currentBatchIndices).map(k => [k, currentBatchIndices[k] as swap]));
     const currentBatchNumber = index_map.get(tokenPair);

     console.log('current_batch_number', currentBatchNumber);

      if (parseInt(currentBatchNumber) === 0) {
        setStatus(BatcherStatus.NONE);
        setVolumes(getEmptyVolumes());
      } else {
        const currentBatchURI =
          bigMapsByIdUri + storage.batch_set.batches + '/keys/' + currentBatchNumber;
        const data = await fetch(currentBatchURI, {
          method: 'GET',
        });
        const jsonData = await data.json();
        const status = Object.keys(jsonData.value.status)[0];
        setStatus(status);
        if (status === BatcherStatus.OPEN) {
          setOpenTime(jsonData.value.status.open);
        }
        setVolumes(scaleVolumeDown(jsonData.value.volumes));
      }
    } catch (error) {
      console.log('Batcher error', error);
    }
  };

  const updateHoldings = async (storage: any) => {
    if (!userAddress) {
      setSellSideAmount(0);
      setBuySideAmount(0);
      return;
    }

    console.log('Storage', storage);

    const fee  = storage.fee_in_mutez;
    setFeeInMutez(fee);

    const valid_swaps = storage.valid_swaps;

    const swap_map = new Map(Object.keys(valid_swaps).map(k => [k, valid_swaps[k]]));
    console.log('swap_map', swap_map);
    setTokenMap(swap_map);

    console.log('valid_swaps', valid_swaps);

    const userBatcherURI = bigMapsByIdUri + storage.user_batch_ordertypes + '/keys/' + userAddress;
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

    for (var i = 0; i < Object.keys(userBatches.value).length; i++) {
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

      for (var j = 0; j < userBatchLength; j++) {
        if (Object.keys(userBatches.value[batchId].at(j).key.side)[0] === BUY) {
          const depositedBuySideAmount = parseInt(userBatches.value[batchId].at(j).value);
          const unconvertedBuySideAmount =
            depositedBuySideAmount - (depositedBuySideAmount / buySideActualVolume) * clearing;
          const unconvertedSellSideAmount =
            (depositedBuySideAmount / buySideActualVolume) * clearing * clearingRate;

          initialBuySideAmount += Math.floor(unconvertedBuySideAmount) / 10 ** buyTokenDecimals;
          initialSellSideAmount += Math.floor(unconvertedSellSideAmount) / 10 ** sellTokenDecimals;
        } else {
          const depositedSellSideAmount = parseInt(userBatches.value[batchId].at(j).value);
          const unconvertedBuySideAmount =
            (depositedSellSideAmount / sellSideActualVolume) * clearing;
          const unconvertedSellSideAmount =
            depositedSellSideAmount -
            (depositedSellSideAmount / sellSideActualVolume) * clearing * clearingRate;

          initialBuySideAmount += Math.floor(unconvertedBuySideAmount) / 10 ** buyTokenDecimals;
          initialSellSideAmount += Math.floor(unconvertedSellSideAmount) / 10 ** sellTokenDecimals;
        }
      }
    }

    setSellSideAmount(initialSellSideAmount);
    setBuySideAmount(initialBuySideAmount);
  };

  const updateHoldingsFromStorage = async () => {
    const storage = await contractsService.getStorage({
      address: contractAddress,
      level: 0,
      path: null,
    });
    await updateHoldings(storage);
  };

  const getBatches = async () => {
    const storage = await contractsService.getStorage({
      address: contractAddress,
      level: 0,
      path: null,
    });

    await getCurrentVolume(storage);
  };
  const handleWebsocket = () => {
    connection.on('token_balances', (msg: any) => {
      console.log('token_balances msg', msg);
      if (!msg.data) return;
      if (!userAddress) return;

      const updatedBuyBalance = getSocketTokenAmount(
        msg.data,
        userAddress,
        buyBalance,
        buyTokenAddress,
      );
      if (updatedBuyBalance !== 0) {
        setBuyBalance({
          ...buyBalance,
          balance: updatedBuyBalance,
        });
      }

      const updatedSellBalance = getSocketTokenAmount(
        msg.data,
        userAddress,
        sellBalance,
        sellTokenAddress,
      );
      if (updatedSellBalance !== 0) {
        setSellBalance({
          ...sellBalance,
          balance: updatedSellBalance,
        });
      }
    });

    // This is the place handling operations and storages
    connection.on('operations', (msg: any) => {
      if (!msg.data) return;
      if (!msg.data[0].storage) return;
      console.log('operations msg storage', msg.data[0].storage);
      if (userAddress) {
        updateHoldings(msg.data[0].storage);
      }
      getCurrentVolume(msg.data[0].storage);
    });

    connection.on('bigmaps', (msg: any) => {
      console.log('bigmaps msg', msg);
      if (!msg.data) return;

      const numerator = msg.data[0].content.value.rate.p;
      const denominator = msg.data[0].content.value.rate.q;

      const scaledPow = buyBalance.token.decimals - sellBalance.token.decimals;
      const scaledRate = scaleAmountUp(numerator / denominator, scaledPow);
      setRate(scaledRate);
    });

    init(userAddress);
  };

  const getTokenBalance = async () => {
    if (userAddress) {
      const balanceURI = REACT_APP_TZKT_URI_API + '/v1/tokens/balances?account=' + userAddress;
      const data = await fetch(balanceURI, { method: 'GET' });
      const balance = await data.json();
      if (Array.isArray(balance)) {
        const baseAmount = getTokenAmount(balance, buyBalance);
        const quoteAmount = getTokenAmount(balance, sellBalance);
        setBuyBalance({ ...buyBalance, balance: baseAmount });
        setSellBalance({ ...sellBalance, balance: quoteAmount });
      }
    } else {
      setBuyBalance({ ...buyBalance, balance: 0 });
      setSellBalance({ ...sellBalance, balance: 0 });
    }
  };

  const getOraclePrice = async () => {
    const rates = await contractsService.getBigMapByNameKeys({
      address: REACT_APP_BATCHER_CONTRACT_HASH,
      name: 'rates_current',
      micheline: MichelineFormat.JSON,
    });

    if (rates.length != 0) {
      const rate = rates.filter((r) => r.key == tokenPair)[0].value;
      const numerator = rate.rate.p;
      const denominator = rate.rate.q;
      const scaledPow = buyBalance.token.decimals - sellBalance.token.decimals;
      const scaledRate = scaleAmountUp(numerator / denominator, scaledPow);
      setRate(scaledRate);
    }
  };

  const persistWallet = () => {
    if (!userAddress) {
      const restoredUserAddress = localStorage.getItem('userAddress');
      const wallet = new BeaconWallet({
        name: 'batcher',
        preferredNetwork: getNetworkType(),
      });
      Tezos.setWalletProvider(wallet);
      setInitialState({ ...initialState, wallet: wallet, userAddress: restoredUserAddress });
    } else {
      Tezos.setWalletProvider(wallet);
    }
  };

  const renderRightContent = (content: ContentType) => {
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
          />
        );
    }
  };

  useEffect(() => {
    getBatches();
    getTokenBalance();
    getOraclePrice();
    handleWebsocket();
    updateHoldingsFromStorage();
    persistWallet();
  }, [userAddress]);

  return (
    <div>
      <BatcherInfo
        buyBalance={buyBalance}
        sellBalance={sellBalance}
        inversion={inversion}
        rate={rate}
        status={status}
        openTime={openTime}
      />
      <BatcherAction
        setContent={setContent}
        tezos={Tezos}
        tokenMap={tokenMap}
        setBuyTokenName={setBuyTokenName}
        setBuyTokenAddress={setBuyTokenAddress}
        setBuyTokenDecimals={setBuyTokenDecimals}
        setBuyTokenStandard={setBuyTokenStandard}
        setSellTokenName={setSellTokenName}
        setSellTokenAddress={setSellTokenAddress}
        setSellTokenDecimals={setSellTokenDecimals}
        setSellTokenStandard={setSellTokenStandard}
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
