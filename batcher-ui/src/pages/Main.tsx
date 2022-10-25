import React, { useState, useEffect } from 'react';
import Exchange from '@/components/Exchange';
import Holdings from '@/components/Holdings';
import OrderBook from '@/components/OrderBook';
import BatcherInfo from '@/components/BatcherInfo';
import BatcherAction from '@/components/BatcherAction';
import { ContentType, token, batch, batch_set, order_book } from '@/extra_utils/types';
import { TezosToolkit } from '@taquito/taquito';
import { ContractsService } from '@dipdup/tzkt-api';
import { Col, Row } from 'antd';
import { useModel } from 'umi';
import { getSocketTokenAmount, getTokenAmount } from '@/extra_utils/utils';
import { connection, init } from '@/extra_utils/webSocketUtils';

const Welcome: React.FC = () => {
  const [content, setContent] = useState<ContentType>(ContentType.SWAP);
  const [Tezos] = useState<TezosToolkit>(new TezosToolkit(REACT_APP_TEZOS_NODE_URI));
  const buyTokenName = 'tzBTC';
  const buyTokenAddress = REACT_APP_TZBTC_HASH;
  const buyTokenDecimals = 8;
  const sellTokenName = 'USDT';
  const sellTokenAddress = REACT_APP_USDT_HASH;
  const sellTokenDecimals = 6;
  const buyToken: token = {
    name: buyTokenName,
    address: buyTokenAddress,
    decimals: buyTokenDecimals,
  };
  const sellToken: token = {
    name: sellTokenName,
    address: sellTokenAddress,
    decimals: sellTokenDecimals,
  };
  const [contractAddress] = useState<string>(REACT_APP_BATCHER_CONTRACT_HASH);
  const chain_api_url = REACT_APP_TZKT_URI_API;
  const contractsService = new ContractsService({
    baseUrl: chain_api_url,
    version: '',
    withCredentials: false,
  });
  const [batches, setBatches] = useState<batch_set>();
  const [previousBatches, setPreviousBatches] = useState<Array<batch>>([]);
  const [bigMapsByIdUri] = useState<string>('' + chain_api_url + '/v1/bigmaps');
  const [currentBatchExists, setCurrentBatchExists] = useState<boolean>(false);
  const [orderBook, setOrderBook] = useState<order_book | undefined>(undefined);
  const [inversion, setInversion] = useState(true);
  const { initialState } = useModel('@@initialState');
  const { userAddress } = initialState;
  const [buyBalance, setBuyBalance] = useState({
    token: buyToken,
    balance: 0,
  });

  const [sellBalance, setSellBalance] = useState({
    token: sellToken,
    balance: 0,
  });

  const get_batches = async () => {
    const storage = await contractsService.getStorage({
      address: contractAddress,
      level: 0,
      path: null,
    });
    const batches: batch_set = await storage.batches;
    setBatches(batches);
    setPreviousBatches(batches?.previous ? [] : batches?.previous);

    let current_batch = undefined;

    try {
      current_batch = await storage.batches.current;
    } catch {}

    setCurrentBatchExists(current_batch === undefined || current_batch === null ? false : true);

    if (currentBatchExists) {
      const order_book: order_book = storage.batches.current.orderbook;
      setOrderBook(order_book);
    }
  };
  const handleWebsocket = () => {
    if (userAddress) {
      connection.onclose(() => init(userAddress));
      connection.on('token_balances', (msg: any) => {
        const updatedBuyBalance = getSocketTokenAmount(msg.data, userAddress, buyBalance);
        if (updatedBuyBalance !== 0) {
          setBuyBalance({
            ...buyBalance,
            balance: updatedBuyBalance,
          });
        }

        const updatedSellBalance = getSocketTokenAmount(msg.data, userAddress, sellBalance);
        if (updatedSellBalance !== 0) {
          setSellBalance({
            ...sellBalance,
            balance: getSocketTokenAmount(msg.data, userAddress, sellBalance),
          });
        }
      });

      // This is the place handling operaions and storages
      connection.on('operations', (msg: any) => {
        console.log('Operations', msg);
      });

      init(userAddress);
    }
  };

  const getTokenBalance = async () => {
    if (userAddress) {
      const balanceURI = REACT_APP_TZKT_URI_API + '/v1/tokens/balances?account=' + userAddress;
      const data = await fetch(balanceURI, { method: 'GET' });
      const balance = await data.json();
      console.log('%cMain.tsx line:111 balance', 'color: #007acc;', balance);
      if (Array.isArray(balance)) {
        const baseAmount = getTokenAmount(balance, buyBalance);
        const quoteAmount = getTokenAmount(balance, sellBalance);
        setBuyBalance({ ...buyBalance, balance: baseAmount });
        setSellBalance({ ...sellBalance, balance: quoteAmount });
      }
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
          />
        );
      case ContentType.ORDER_BOOK:
        return (
          <OrderBook
            orderBookExists={currentBatchExists}
            orderBook={orderBook}
            buyToken={buyToken}
            sellToken={sellToken}
          />
        );
      case ContentType.REDEEM_HOLDING:
        return (
          <Holdings
            tezos={Tezos}
            bigMapsByIdUri={bigMapsByIdUri}
            contractAddress={contractAddress}
            previousBatches={previousBatches}
            buyToken={buyToken}
            sellToken={sellToken}
          />
        );
      default:
        return (
          <Exchange
            buyBalance={buyBalance}
            sellBalance={sellBalance}
            inversion={inversion}
            setInversion={setInversion}
          />
        );
    }
  };

  useEffect(() => {
    (async () => get_batches())();
    getTokenBalance();
    handleWebsocket();
  }, [userAddress]);

  return (
    <div>
      <BatcherInfo buyBalance={buyBalance} sellBalance={sellBalance} inversion={inversion} />
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
