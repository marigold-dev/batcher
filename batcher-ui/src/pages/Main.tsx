import React, { useState, useEffect } from 'react';
import Exchange from '@/components/Exchange';
import About from '@/components/About';
import OrderBook from '@/components/OrderBook';
import BatcherInfo from '@/components/BatcherInfo';
import BatcherAction from '@/components/BatcherAction';
import {
  ContentType,
  token,
  order_book,
  BatcherStatus,
  BatchSet,
  BUY,
  MINUS,
  EXACT,
} from '@/extra_utils/types';
import { TezosToolkit } from '@taquito/taquito';
import { ContractsService, MichelineFormat } from '@dipdup/tzkt-api';
import { Col, Row } from 'antd';
import { useModel } from 'umi';
import { getSocketTokenAmount, getTokenAmount, scaleAmountDown } from '@/extra_utils/utils';
import { connection, init } from '@/extra_utils/webSocketUtils';
import { scaleAmountUp, getEmptyOrderBook } from '@/extra_utils/utils';
import NewHoldings from '@/components/NewHoldings';

const Welcome: React.FC = () => {
  const [content, setContent] = useState<ContentType>(ContentType.SWAP);
  const [Tezos] = useState<TezosToolkit>(new TezosToolkit(REACT_APP_TEZOS_NODE_URI));
  const buyTokenName = 'tzBTC';
  const buyTokenAddress = REACT_APP_TZBTC_HASH;
  const buyTokenDecimals = 8;
  const buyTokenStandard = 'FA1.2 token';
  const sellTokenName = 'USDT';
  const sellTokenAddress = REACT_APP_USDT_HASH;
  const sellTokenDecimals = 6;
  const sellTokenStandard = 'FA2 token';
  const tokenPair = buyTokenName + '/' + sellTokenName;
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
  const [orderBook, setOrderBook] = useState<order_book | undefined>(undefined);
  const [inversion, setInversion] = useState(true);
  const { initialState } = useModel('@@initialState');
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

  const getCurrentOrderbook = async (batchSet: BatchSet) => {
    try {
      const currentBatchNumber = batchSet.current_batch_number;

      if (parseInt(currentBatchNumber) === 0) {
        setStatus(BatcherStatus.NONE);
        setOrderBook(getEmptyOrderBook());
      } else {
        const currentBatchURI = bigMapsByIdUri + batchSet.batches + '/keys/' + currentBatchNumber;
        const data = await fetch(currentBatchURI, {
          method: 'GET',
        });
        const jsonData = await data.json();
        const status = Object.keys(jsonData.value.status)[0];
        setStatus(status);
        if (status === BatcherStatus.OPEN) {
          setOpenTime(jsonData.value.status.open);
        }
        setOrderBook(jsonData.value.orderbook);
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

    const currentBatchNumber = storage.batch_set.current_batch_number;
    const userOrderBookURI = bigMapsByIdUri + storage.user_orderbook + '/keys/' + userAddress;
    const userOrderBookData = await fetch(userOrderBookURI, { method: 'GET' });
    let userOrderBooks = null;
    try {
      userOrderBooks = await userOrderBookData.json();
    } catch (error) {
      console.error(error);
      return;
    }

    if (!Array.isArray(userOrderBooks.value.open) || userOrderBooks.value.open.length == 0) {
      return;
    }

    const openHoldingOrderBooks = userOrderBooks.value.open.map((orderbook) => {
      if (orderbook.batch_number !== currentBatchNumber) {
        return orderbook;
      }
    });

    console.log(2333, openHoldingOrderBooks);

    const batchesURI = bigMapsByIdUri + storage.batch_set.batches + '/keys';
    const batchesData = await fetch(batchesURI, { method: 'GET' });
    let batches = null;
    try {
      batches = await batchesData.json();
    } catch (error) {
      console.error(error);
      return;
    }

    const openHoldingOrderBookKeys = openHoldingOrderBooks.map(
      (orderbook) => orderbook.batch_number,
    );
    // This is the open batches this current user is included
    const chosenBatches = batches.filter((batch) => openHoldingOrderBookKeys.includes(batch.key));
    console.log(333, chosenBatches);

    let initialBuySideAmount = 0;
    let initialSellSideAmount = 0;

    for (var i = 0; i < chosenBatches.length; i++) {
      console.log(444, chosenBatches);
      const batch = chosenBatches.at(i);

      const clearingKey = Object.keys(batch.value.status.cleared.clearing.clearing_tolerance)[0];
      const clearing = parseInt(
        batch.value.status.cleared.clearing.clearing_volumes[clearingKey.toLowerCase()],
      );

      let clearingRate = 0;
      const originalClearingRate =
        parseInt(batch.value.status.cleared.rate.rate.val) *
        10 ** parseInt(batch.value.status.cleared.rate.rate.pow);
      if (clearingKey === MINUS) {
        clearingRate = originalClearingRate / 1.0001;
      } else if (clearingKey === EXACT) {
        clearingRate = originalClearingRate;
      } else {
        clearingRate = originalClearingRate * 1.0001;
      }

      console.log(2222, clearingRate);

      const buySideActualVolume = parseInt(
        batch.value.status.cleared.clearing.prorata_equivalence.buy_side_actual_volume,
      );
      const sellSideActualVolume = parseInt(
        batch.value.status.cleared.clearing.prorata_equivalence.sell_side_actual_volume,
      );

      if (Object.keys(openHoldingOrderBooks.at(i).side)[0] === BUY) {
        const depositedBuySideAmount = parseInt(openHoldingOrderBooks.at(i).swap.from.amount);
        const unconvertedBuySideAmount =
          depositedBuySideAmount - (depositedBuySideAmount / buySideActualVolume) * clearing;
        const unconvertedSellSideAmount =
          (depositedBuySideAmount / buySideActualVolume) * clearing * clearingRate;
        initialBuySideAmount += scaleAmountDown(unconvertedBuySideAmount, buyTokenDecimals);
        initialSellSideAmount += scaleAmountDown(unconvertedSellSideAmount, sellTokenDecimals);
      } else {
        const depositedSellSideAmount = parseInt(openHoldingOrderBooks.at(i).swap.from.amount);
        const unconvertedBuySideAmount =
          (depositedSellSideAmount / sellSideActualVolume) * clearing;
        const unconvertedSellSideAmount =
          depositedSellSideAmount -
          (depositedSellSideAmount / sellSideActualVolume) * clearing * clearingRate;

        initialBuySideAmount += scaleAmountDown(unconvertedBuySideAmount, buyTokenDecimals);
        initialSellSideAmount += scaleAmountDown(unconvertedSellSideAmount, sellTokenDecimals);
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

    console.log(999, storage);

    await updateHoldings(storage);
  };

  const getBatches = async () => {
    const storage = await contractsService.getStorage({
      address: contractAddress,
      level: 0,
      path: null,
    });

    console.log('%cMain.tsx line:109 storage', 'color: #007acc;', storage);

    await getCurrentOrderbook(storage.batch_set);
  };
  const handleWebsocket = () => {
    connection.on('token_balances', (msg: any) => {
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

      console.log('Operations', msg);
      getCurrentOrderbook(msg.data[0].storage.batch_set);
      updateHoldings(msg.data[0].storage);
    });

    connection.on('bigmaps', (msg: any) => {
      if (!msg.data) return;

      const scaledRate = msg.data[0].content.value.rate.val;
      const pow = msg.data[0].content.value.rate.pow;
      const scaledPow =
        Number.parseFloat(pow) + buyBalance.token.decimals - sellBalance.token.decimals;
      const currentRate = scaleAmountUp(Number.parseFloat(scaledRate), scaledPow);
      setRate(currentRate);
    });

    init(userAddress);
    Tezos.setWalletProvider(wallet);
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
      const scaledRate = rate.rate.val;
      const pow = rate.rate.pow;
      const scaledPow =
        Number.parseFloat(pow) + buyBalance.token.decimals - sellBalance.token.decimals;
      const currentRate = scaleAmountUp(Number.parseFloat(scaledRate), scaledPow);
      setRate(currentRate);
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
          />
        );
      case ContentType.ORDER_BOOK:
        return <OrderBook orderBook={orderBook} buyToken={buyToken} sellToken={sellToken} />;
      case ContentType.REDEEM_HOLDING:
        return (
          <NewHoldings
            tezos={Tezos}
            userAddress={userAddress}
            contractAddress={contractAddress}
            buyToken={buyToken}
            sellToken={sellToken}
            buyTokenHolding={buySideAmount}
            sellTokenHolding={sellSideAmount}
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
      <BatcherAction setContent={setContent} />
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
