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

  // const updateFromStorage = async (storage: any) => {
  //   updateBigMapIds(storage);
  //   zeroHoldings(storage, setOpenHoldings, setClearedHoldings);
  //   await updateTokenDetails(storage);
  //   await getBatches(storage);
  //   await updateSwapMap(storage);
  //   await setFee(storage);
  //   await getOraclePrice();
  //   await getTokenBalance();
  //   await updateHoldings(storage);
  //   await getCurrentVolume(storage);
  // };

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
    <div className="flex flex-col md:mx-[15%] mx-8">
      <BatcherInfo />
      <div className="flex md:flex-row flex-col">
        <PriceStrategy />
        <Exchange />
      </div>
    </div>
  );
};

export default Welcome;
