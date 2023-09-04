import React, { useEffect } from 'react';
import Exchange from '../components/Exchange';
import BatcherInfo from '../components/BatcherInfo';
import PriceStrategy from '../components/PriceStrategy';

import { useSelector, useDispatch } from 'react-redux';
import { userAddressSelector } from '../src/reducers';
import {
  fetchUserBalances,
  batcherSetup,
  batcherUnsetup,
} from '../src/actions';


const Welcome = () => {
  const userAddress = useSelector(userAddressSelector);

  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(batcherSetup());
    return () => {
      dispatch(batcherUnsetup());
    };
  }, [dispatch]);

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

export default Welcome;
