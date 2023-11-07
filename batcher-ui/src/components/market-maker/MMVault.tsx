import React, { useEffect } from 'react';
import SelectMMPair from './SelectMMPair';
import { useSelector } from 'react-redux';
import { fetchUserBalances } from '@/actions';
import { userAddressSelector } from '@/reducers';
import { useDispatch } from 'react-redux';
import Vault from './Vault';

const MMVaultComponent = () => {
  const dispatch = useDispatch();
  const userAddress = useSelector(userAddressSelector);

  useEffect(() => {
    if (userAddress) dispatch(fetchUserBalances());
  }, [dispatch, userAddress]);

  return (
    <div>
      <div className="flex grow flex-col justify-center md:flex-row p-3 border-solid border-2 border-lightgray my-2">
        <div className="p-3">
          <p className="text-xl text-center">Market Maker Vaults</p>
        </div>
      </div>
      <SelectMMPair />
      <Vault />
    </div>
  );
};
export default MMVaultComponent;
