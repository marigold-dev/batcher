import React, { useEffect, useState } from 'react';
import { useDispatch } from 'react-redux';
import Image from 'next/image';
import { connectedWallet, disconnectedWallet } from '.././src/actions';
import BatcherLogo from '../img/batcher-logo.png';
import { useWallet } from '.././contexts/wallet';
import ChoosePairs from './ChoosePairs';
import Menu from './Menu';
import { Cross1Icon, HamburgerMenuIcon } from '@radix-ui/react-icons';
import LinkComponent from './Link';

interface NavBarProps {
  isMenuOpen: boolean;
  setIsMenuOpen(arg: boolean): void;
}

const NavBar = ({ isMenuOpen, setIsMenuOpen }: NavBarProps) => {
  const dispatch = useDispatch();

  const walletCtx = useWallet();
  const userAddress = walletCtx.state.userAddress;

  const [isOpen, setIsOpen] = useState(true);

  useEffect(() => {
    userAddress
      ? dispatch(connectedWallet({ userAddress }))
      : dispatch(disconnectedWallet());
  }, [userAddress, dispatch]);

  return (
    <>
      {isOpen && (
        <div className="fixed top-0 z-50 flex h-12 w-full items-center justify-between bg-primary px-4 text-xs text-white md:text-base">
          <div className="flex">
            <span className="font-light mr-2">{'Make sure the URL is '}</span>
            <p>
              {process.env.NEXT_PUBLIC_NETWORK_TARGET === 'MAINNET'
                ? 'batcher.marigold.dev'
                : 'ghostnet.batcher.marigold.dev'}
            </p>
          </div>
          <button onClick={() => setIsOpen(false)}>
            <Cross1Icon className="h-full" />
          </button>
        </div>
      )}

      <div
        className={`${
          isOpen && 'mt-12'
        } flex flex-row justify-between font-custom border-b-4 border-lightgray border-solid bg-darkgray md:text-base`}>
        <div className="flex gap-2 p-2 items-center">
          <Image alt="Batcher Logo" src={BatcherLogo} height={32} />
          <p>BATCHER</p>
          <div className="hidden md:flex md:ml-8 md:items-center">
            <LinkComponent path="/" title={'Swap'} />
            <LinkComponent path="/volumes" title={'Volumes'} />
            <LinkComponent path="/holdings" title={'Redeem Holdings'} />
            <LinkComponent path="/about" title={'About'} />
          </div>
        </div>

        <div className="flex">
          <ChoosePairs />
          {userAddress ? (
            <p className="p-4">{`${userAddress.substring(
              0,
              3
            )}...${userAddress.substring(userAddress.length - 3)}`}</p>
          ) : null}
          <button
            type="button"
            className="text-white bg-primary rounded py-2 px-4 m-2 md:hidden"
            // onClick={() =>
            //   userAddress
            //     ? walletCtx.disconnectWallet()
            //     : walletCtx.connectWallet()
            // }
            onClick={() => setIsMenuOpen(!isMenuOpen)}>
            {/* {userAddress ? 'Disconnect Wallet' : 'Connect Wallet'} */}
            <HamburgerMenuIcon />
          </button>
          <button
            type="button"
            className="text-white bg-primary rounded py-2 px-4 m-2 hidden md:flex hover:bg-red-500"
            onClick={() => {
              setIsMenuOpen(false);
              userAddress
                ? walletCtx.disconnectWallet()
                : walletCtx.connectWallet();
            }}>
            {userAddress ? 'Disconnect Wallet' : 'Connect Wallet'}
          </button>
        </div>
      </div>

      {isMenuOpen && <Menu setIsMenuOpen={setIsMenuOpen} />}
    </>
  );
};
export default NavBar;
