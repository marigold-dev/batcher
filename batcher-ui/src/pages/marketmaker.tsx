import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { userAddressSelector } from '@/reducers';
import { getMarketHoldings as getMarketHoldingsAction } from '@/actions';
import MMVault from '@/components/market-maker/MMVault';

const MarketMakerHoldings = () => {
  const contractAddress =
    process.env.NEXT_PUBLIC_MARKET_MAKER_CONTRACT_HASH || '';

  const userAddress = useSelector(userAddressSelector);

  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(getMarketHoldingsAction(contractAddress, userAddress || ''));
  }, [userAddress, contractAddress, dispatch]);

  return (
    <div className="flex flex-col md:mx-[15%] mx-4">
      <MMVault />
    </div>
  );
};

export default MarketMakerHoldings;
