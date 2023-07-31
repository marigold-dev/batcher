import Footer from '../components/Footer';
import React, { useEffect } from 'react';
import { AppProps } from 'next/app';
import { TezosToolkitProvider } from '../contexts/tezos-toolkit';
import { WalletProvider } from '../contexts/wallet';
import '../styles/globals.css';
import { Provider } from 'react-redux';
import { store } from '../src/store';
import NavBar from '../components/NavBar';
import ReactGA from 'react-ga4';
import * as api from '@tzkt/sdk-api';

process.env.REACT_APP_GA_TRACKING_ID &&
  ReactGA.initialize(process.env.REACT_APP_GA_TRACKING_ID);

const App = ({ Component }: AppProps) => {
  // Override TZKT base url if we are in ghostnet
  useEffect(() => {
    if (process.env.REACT_APP_NETWORK_TARGET === 'GHOSTNET') {
      console.log('GHOSTNET !!');
      api.defaults.baseUrl = 'https://api.ghostnet.tzkt.io/';
    }
  }, []);

  return (
    <Provider store={store}>
      <TezosToolkitProvider>
        <WalletProvider>
          <div className="flex flex-col justify-between h-screen">
            <NavBar />
            <Component />
            <Footer />
          </div>
        </WalletProvider>
      </TezosToolkitProvider>
    </Provider>
  );
};

export default App;