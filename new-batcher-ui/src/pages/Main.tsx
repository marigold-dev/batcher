import React from 'react';
import Exchange from '@/components/Exchange';

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

  return (
    <div>
      <Exchange baseToken={baseToken} quoteToken={quoteToken} />
    </div>
  );
};

export default Welcome;
