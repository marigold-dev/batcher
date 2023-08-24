import React from 'react';
import LinkComponent from './Link';
import { useWallet } from 'contexts/wallet';

interface MenuProps {
  setIsMenuOpen(arg: boolean): void;
}

const Menu = ({ setIsMenuOpen }: MenuProps) => {
  const walletCtx = useWallet();
  const userAddress = walletCtx.state.userAddress;

  return (
    <div
      className={`w-full text-left border-b-4 border-lightgray border-solid`}>
      <button
        type="button"
        className="text-white bg-primary rounded py-2 px-4 m-2"
        onClick={() => {
          setIsMenuOpen(false);
          userAddress
            ? walletCtx.disconnectWallet()
            : walletCtx.connectWallet();
        }}>
        {userAddress ? 'Disconnect Wallet' : 'Connect Wallet'}
      </button>
      <LinkComponent
        path="/"
        title={'Swap'}
        onClick={() => setIsMenuOpen(false)}
      />
      <LinkComponent
        path="/volumes"
        title={'Volumes'}
        onClick={() => setIsMenuOpen(false)}
      />
      <LinkComponent
        path="/holdings"
        title={'Redeem Holdings'}
        onClick={() => setIsMenuOpen(false)}
      />
      <LinkComponent
        path="/about"
        title={'About'}
        onClick={() => setIsMenuOpen(false)}
      />
    </div>
  );
};

export default Menu;
