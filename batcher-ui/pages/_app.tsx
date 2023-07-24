import Footer from '../components/Footer';
import React from 'react';
// import { Spin, Image } from 'antd';
// import MarigoldLogo from '../img/marigold-logo.png';
// import { TezosToolkit } from '@taquito/taquito';
import { AppProps } from 'next/app';
import { AppProvider } from '../contexts';
import { TezosToolkitProvider } from '../contexts/tezos-toolkit';
import "../styles/globals.css";

export default ({ Component }: AppProps) => {
  return (
    <AppProvider>
      <TezosToolkitProvider>
        <Component />
        <Footer />
      </TezosToolkitProvider>
    </AppProvider>
  );
};
