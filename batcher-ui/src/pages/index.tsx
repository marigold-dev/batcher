import React, { useEffect } from 'react';
import Exchange from '@/components/batcher/Exchange';
import BatcherInfo from '@/components/batcher/BatcherInfo';
import PriceStrategy from '@/components/batcher/PriceStrategy';

import { useSelector, useDispatch } from 'react-redux';
import { currentPairSelector, userAddressSelector } from '@/reducers';
import { fetchUserBalances, batcherUnsetup, getPairsInfos } from '@/actions';

const Swap = () => {
  const userAddress = useSelector(userAddressSelector);
  const tokenPair = useSelector(currentPairSelector);

  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(getPairsInfos(tokenPair));

    return () => {
      dispatch(batcherUnsetup());
    };
  }, [dispatch, tokenPair]);

  useEffect(() => {
    if (userAddress) {
      dispatch(fetchUserBalances());
    }
  }, [userAddress, dispatch]);

  return (
    <div className="flex flex-col md:mx-[15%] mx-4">
      <BatcherInfo />
      <div className="flex md:flex-row flex-col">
        <PriceStrategy />
        <Exchange />
      </div>
    </div>
  );
};

export default Swap;
