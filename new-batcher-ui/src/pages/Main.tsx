import React, { useEffect, useState } from 'react';
import Exchange from '@/components/Exchange';
import BatcherInfo from '@/components/BatcherInfo';
import BatcherAction from '@/components/BatcherAction';
import { ContentType } from '@/extra_utils/types';
import { useModel } from 'umi';
import { getSocketTokenAmount, getTokenAmount } from '@/extra_utils/utils';
import { connection, init } from '@/extra_utils/webSocketUtils';

const Welcome: React.FC = () => {
  const [content, setContent] = useState(ContentType.SWAP);
  const [inversion, setInversion] = useState(true);

  const { initialState } = useModel('@@initialState');
  const { userAddress } = initialState;

  const [baseBalance, setBaseBalance] = useState({
    name: 'tzBTC',
    address: REACT_APP_TZBTC_HASH,
    decimal: 8,
    balance: 0,
  });
  const [quoteBalance, setQuoteBalance] = useState({
    name: 'USDT',
    address: REACT_APP_USDT_HASH,
    decimal: 6,
    balance: 0,
  });

  const handleWebsocket = () => {
    console.log(444, baseBalance);
    if (userAddress) {
      connection.onclose(init);
      connection.on('token_balances', (msg: any) => {
        const updatedBaseBalance = getSocketTokenAmount(msg.data, userAddress, baseBalance);
        if (updatedBaseBalance !== 0) {
          setBaseBalance({
            ...baseBalance,
            balance: updatedBaseBalance,
          });
        }

        const updatedQuoteBalance = getSocketTokenAmount(msg.data, userAddress, quoteBalance);
        if (updatedQuoteBalance !== 0) {
          setQuoteBalance({
            ...quoteBalance,
            balance: getSocketTokenAmount(msg.data, userAddress, quoteBalance),
          });
        }
      });
      init(userAddress);
    }
  };

  const getTokenBalance = async () => {
    if (userAddress) {
      const balanceURI = REACT_APP_TZKT_URI_API + '/v1/tokens/balances?account=' + userAddress;
      const data = await fetch(balanceURI, { method: 'GET' });
      const balance = await data.json();
      if (Array.isArray(balance)) {
        const baseAmount = getTokenAmount(balance, baseBalance);
        const quoteAmount = getTokenAmount(balance, quoteBalance);
        setBaseBalance({ ...baseBalance, balance: baseAmount });
        setQuoteBalance({ ...quoteBalance, balance: quoteAmount });
      }
    }
  };

  useEffect(() => {
    getTokenBalance();
    handleWebsocket();
  }, [userAddress]);

  const renderRightContent = (content: ContentType) => {
    switch (content) {
      case ContentType.SWAP:
        return (
          <Exchange
            baseBalance={baseBalance}
            quoteBalance={quoteBalance}
            inversion={inversion}
            setInversion={setInversion}
          />
        );
      case ContentType.ORDER_BOOK:
        return <div />;
      case ContentType.REDEEM_HOLDING:
        return <div />;
      default:
        return (
          <Exchange
            baseBalance={baseBalance}
            quoteBalance={quoteBalance}
            inversion={inversion}
            setInversion={setInversion}
          />
        );
    }
  };

  return (
    <div>
      <BatcherInfo baseBalance={baseBalance} quoteBalance={quoteBalance} inversion={inversion} />
      <BatcherAction setContent={setContent} />
      {renderRightContent(content)}
    </div>
  );
};

export default Welcome;
