import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  saveToLocalStorageSelector,
  userAddressSelector,
} from '../../src/reducers';
// import { isSome } from 'fp-ts/Option';
import Image from 'next/image';
import {
  connectWallet as connectWalletAction,
  disconnectWallet as disconnectWalletAction,
  hydrateBatcherState,
  setupTezosToolkit,
} from '../../src/actions';
import BatcherLogo from '../../img/batcher-logo.png';
import { getByKey, setByKey } from 'extra_utils/local-storage';

export type SiderTheme = 'light' | 'dark';

const GlobalHeaderRight: React.FC = () => {
  const dispatch = useDispatch();
  const userAddress = useSelector(userAddressSelector);
  const batcherState = useSelector(saveToLocalStorageSelector);

  // TODO: rewrite this
  // if (!state || !state.settings) {
  //   return null;
  // }

  // const { navTheme, layout } = state.settings;
  // let className = '.right';

  // if ((navTheme === 'dark' && layout === 'top') || layout === 'mix') {
  //   className = `.right .dark`; //TODO: rewrite this
  // }

  // const menuProps = {
  //   items,
  //   onClick: !state.userAddress
  //     ? () => connectWallet()
  //     : () => disconnectWallet(),
  // };

  const connectWallet = () => {
    console.info('WALLET : connecting');
    dispatch(connectWalletAction());
  };

  const disconnectWallet = () => {
    console.info('WALLET : disconnecting');
    dispatch(disconnectWalletAction());
    // TODO: websocket connection ?
    // await websocketConnection.stop();
  };

  useEffect(() => {
    if (process.env.REACT_APP_LOCAL_STORAGE_KEY_STATE) {
      dispatch(
        hydrateBatcherState(
          getByKey(process.env.REACT_APP_LOCAL_STORAGE_KEY_STATE)
        )
      );
    }
    dispatch(setupTezosToolkit());
  }, []);

  useEffect(() => {
    if (!userAddress) {
      setByKey(process.env.REACT_APP_LOCAL_STORAGE_KEY_STATE, {});
    } else {
      setByKey(process.env.REACT_APP_LOCAL_STORAGE_KEY_STATE, batcherState);
    }
  }, [userAddress]);

  return (
    <div className="flex flex-row justify-between font-custom border-b-2 border-[#7B7B7E] border-solid">
      <div className="flex gap-2 p-2 items-center">
        <Image alt="Batcher Logo" src={BatcherLogo} height={32} />
        <p>BATCHER</p>
      </div>
      <button
        type="button"
        className="text-[white] bg-[#ff4d4f] rounded py-2 px-4 m-2"
        onClick={() => (userAddress ? disconnectWallet() : connectWallet())}>
        {userAddress ? 'Disconnect Wallet' : 'Connect Wallet'}
      </button>
    </div>
  );
};
export default GlobalHeaderRight;
