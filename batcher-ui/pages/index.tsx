import React, { useEffect } from 'react';
import Exchange from '../src/components/Exchange';
import BatcherInfo from '../src/components/BatcherInfo';
import PriceStrategy from '../src/components/PriceStrategy';

import { useSelector, useDispatch } from 'react-redux';
import { currentPairSelector, userAddressSelector } from '../src/reducers';
import {
  fetchUserBalances,
  batcherSetup,
  batcherUnsetup,
  getPairsInfos,
} from '../src/actions';

const Swap = () => {
  const userAddress = useSelector(userAddressSelector);
  const tokenPair = useSelector(currentPairSelector);

  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(batcherSetup());

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
