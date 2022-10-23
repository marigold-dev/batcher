import React, { useState } from 'react';
import Exchange from '@/components/Exchange';
import BatcherInfo from '@/components/BatcherInfo';
import BatcherAction from '@/components/BatcherAction';
import { ContentType } from '@/extra_utils/types';

const Welcome: React.FC = () => {
  const baseToken = {
    name: 'tzBTC',
    address: REACT_APP_TZBTC_HASH,
    decimal: 8,
  };
  const quoteToken = {
    name: 'USDT',
    address: REACT_APP_USDT_HASH,
    decimal: 6,
  };

  const [content, setContent] = useState<ContentType>(ContentType.SWAP);

  const renderRightContent = (content: ContentType) => {
    switch (content) {
      case ContentType.SWAP:
        return <Exchange baseToken={baseToken} quoteToken={quoteToken} />;
      case ContentType.ORDER_BOOK:
        return <div />;
      case ContentType.REDEEM_HOLDING:
        return <div />;
      default:
        return <Exchange baseToken={baseToken} quoteToken={quoteToken} />;
    }
  };

  return (
    <div>
      <BatcherInfo baseToken={baseToken} quoteToken={quoteToken} />
      <BatcherAction setContent={setContent} />
      {renderRightContent(content)}
    </div>
  );
};

export default Welcome;
