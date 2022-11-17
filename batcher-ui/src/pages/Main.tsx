import React, { useState, useEffect } from 'react';
import Exchange from '@/components/Exchange';
import Holdings from '@/components/Holdings';
import About from '@/components/About';
import OrderBook from '@/components/OrderBook';
import BatcherInfo from '@/components/BatcherInfo';
import BatcherAction from '@/components/BatcherAction';
import {
  ContentType,
  ContractStorage,
  token,
  batch,
  batch_set,
  order_book,
  BatcherStatus,
} from '@/extra_utils/types';
import { TezosToolkit } from '@taquito/taquito';
import { ContractsService, MichelineFormat } from '@dipdup/tzkt-api';
import { Col, Row } from 'antd';
import { useModel } from 'umi';
import { getSocketTokenAmount, getTokenAmount } from '@/extra_utils/utils';
import { connection, connection_side, init } from '@/extra_utils/webSocketUtils';
import { scaleAmountUp, getEmptyOrderBook } from '@/extra_utils/utils';

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
  const [batches, setBatches] = useState<batch_set>();
  const [previousTreasuries, setPreviousTreasuries] = useState<Array<number>>([]);
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

  const process_batches_and_order_book = (order_book: order_book, treasuries: Array<number>) => {
    try {
      setOrderBook(order_book);
      setPreviousTreasuries(treasuries);
    } catch (error: any) {
      setPreviousTreasuries([]);
      setOrderBook(getEmptyOrderBook());
    }
  };

  const getBatches = async () => {
    const storage = await contractsService.getStorage({
      address: contractAddress,
      level: 0,
      path: null,
    });

    try {
      process_batches_and_order_book(
        storage.batches.current ? storage.batches.current.orderbook : getEmptyOrderBook(),
        storage.batches.previous ? storage.batches.previous.map((p: batch) => p.treasury) : [],
      );

      if (!storage.batches.current) {
        setStatus(BatcherStatus.NONE);
      } else {
        const status = Object.keys(storage.batches.current.status)[0];
        setStatus(status);
        if (status === BatcherStatus.OPEN) {
          setOpenTime(storage.batches.current.status.open);
        }
      }
    } catch (error) {
      console.log('Batcher error', error);
    }
  };
  const handleWebsocket = () => {
    connection.on('token_balances', (msg: any) => {
      if (!msg.data) return;
      if (!userAddress) return;

      const updatedBuyBalance = getSocketTokenAmount(msg.data, userAddress, buyBalance);
      if (updatedBuyBalance !== 0) {
        setBuyBalance({
          ...buyBalance,
          balance: updatedBuyBalance,
        });
      }

    });

    connection_side.on('token_balances', (msg: any) => {
      if (!msg.data) return;
      if (!userAddress) return;

      const updatedSellBalance = getSocketTokenAmount(msg.data, userAddress, sellBalance);
      if (updatedSellBalance !== 0) {
        setSellBalance({
          ...sellBalance,
          balance: getSocketTokenAmount(msg.data, userAddress, sellBalance),
        });
      }
    });
    // This is the place handling operations and storages
    connection.on('operations', (msg: any) => {
      if (!msg.data) return;

      console.log('Operations', msg);

      const batches = msg.data[0].storage.batches;

      process_batches_and_order_book(
        batches.current ? batches.current.orderbook : getEmptyOrderBook(),
        batches.previous ? batches.previous.map((p: batch) => p.treasury) : [],
      );

      try {
        if (!batches.current) {
          setStatus(BatcherStatus.NONE);
        } else {
          const status = Object.keys(batches.current.status)[0];
          setStatus(status);
          if (status === BatcherStatus.OPEN) {
            setOpenTime(batches.current.status.open);
          }
        }
      } catch (error: any) {
        console.log(error);
      }
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
          <Holdings
            tezos={Tezos}
            bigMapsByIdUri={bigMapsByIdUri}
            userAddress={userAddress}
            contractAddress={contractAddress}
            previousTreasuries={previousTreasuries}
            buyToken={buyToken}
            sellToken={sellToken}
          />
        );
      case ContentType.ABOUT:
        return (
          <About />
        );
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
