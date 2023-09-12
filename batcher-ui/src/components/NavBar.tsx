import React, { useEffect } from 'react';
import { useDispatch } from 'react-redux';
import Image from 'next/image';
import { connectedWallet, disconnectedWallet } from '../actions';
import { useWallet } from '../contexts/wallet';
import Menu from './Menu';
import LinkComponent from './Link';
import { faBars } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import Copy from './Copy';

interface NavBarProps {
  isMenuOpen: boolean;
  setIsMenuOpen(arg: boolean): void;
}

const NavBar = ({ isMenuOpen, setIsMenuOpen }: NavBarProps) => {
  const dispatch = useDispatch();

  const walletCtx = useWallet();
  const userAddress = walletCtx.state.userAddress;

  useEffect(() => {
    userAddress
      ? dispatch(connectedWallet({ userAddress }))
      : dispatch(disconnectedWallet());
  }, [userAddress, dispatch]);

  return (
    <>
      <div className="flex flex-row justify-between font-custom border-b-4 border-lightgray border-solid bg-darkgray md:text-base">
        <div className="flex gap-2 p-2 items-center">
          <Image
            alt="Batcher Logo"
            src={'/batcher-logo.png'}
            height={32}
            width={64}
          />
          <p>BATCHER</p>
          <div className="hidden md:flex md:ml-8 md:items-center">
            <LinkComponent path="/" title={'Swap'} />
            <LinkComponent path="/volumes" title={'Volumes'} />
            <LinkComponent path="/holdings" title={'Redeem Holdings'} />
            <LinkComponent
              path="/marketmaker"
              title={'Community Marker Maker'}
            />
            <LinkComponent path="/about" title={'About'} />
          </div>
        </div>

        <div className="flex">
          {userAddress ? (
            <Copy value={userAddress} disabled={false}>
              <p className="p-4">{`${userAddress.substring(
                0,
                3
              )}...${userAddress.substring(userAddress.length - 3)}`}</p>
            </Copy>
          ) : null}
          <button
            type="button"
            className="text-white bg-primary rounded py-2 px-4 m-2 md:hidden"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
          >
            <FontAwesomeIcon icon={faBars} size="xl" />
          </button>
          <button
            type="button"
            className="text-white bg-primary rounded py-2 px-4 m-2 hidden md:flex hover:bg-red-500"
            onClick={() => {
              setIsMenuOpen(false);
              userAddress
                ? walletCtx.disconnectWallet()
                : walletCtx.connectWallet();
            }}
          >
            {userAddress ? 'Disconnect Wallet' : 'Connect Wallet'}
          </button>
        </div>
      </div>

      {isMenuOpen && <Menu setIsMenuOpen={setIsMenuOpen} />}
    </>
  );
};
export default NavBar;
