import React, { useEffect } from 'react';
import { useDispatch } from 'react-redux';
// import { isSome } from 'fp-ts/Option';
import Image from 'next/image';
import { connectedWallet, disconnectedWallet } from '../../src/actions';
import BatcherLogo from '../../img/batcher-logo.png';
import { useWallet } from '../../contexts/wallet';

export type SiderTheme = 'light' | 'dark';

const GlobalHeaderRight: React.FC = () => {
  const dispatch = useDispatch();

  const walletCtx = useWallet();
  const userAddress = walletCtx.state.userAddress;

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

  useEffect(() => {
    userAddress
      ? dispatch(connectedWallet({ userAddress }))
      : dispatch(disconnectedWallet());
  }, [userAddress, dispatch]);

  return (
    <div className="flex flex-row justify-between font-custom border-b-2 border-[#7B7B7E] border-solid">
      <div className="flex gap-2 p-2 items-center">
        <Image alt="Batcher Logo" src={BatcherLogo} height={32} />
        <p>BATCHER</p>
      </div>
      <button
        type="button"
        className="text-[white] bg-[#ff4d4f] rounded py-2 px-4 m-2"
        onClick={() =>
          userAddress ? walletCtx.disconnectWallet() : walletCtx.connectWallet()
        }>
        {userAddress ? 'Disconnect Wallet' : 'Connect Wallet'}
      </button>
    </div>
  );
};
export default GlobalHeaderRight;
