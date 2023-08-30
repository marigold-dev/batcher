import Footer from '../components/Footer';
import React, { useEffect, useState } from 'react';
import { AppProps } from 'next/app';
import { TezosToolkitProvider } from '../contexts/tezos-toolkit';
import { WalletProvider } from '../contexts/wallet';
import { EventsProvider } from '../contexts/events';
import '../styles/globals.css';
import { Provider } from 'react-redux';
import { store } from '../src/store';
import NavBar from '../components/NavBar';
import ReactGA from 'react-ga4';
import * as api from '@tzkt/sdk-api';
import Head from 'next/head';
import { config } from '@fortawesome/fontawesome-svg-core';
import '@fortawesome/fontawesome-svg-core/styles.css';

config.autoAddCss = false;

process.env.NEXT_PUBLIC_GA_TRACKING_ID &&
  ReactGA.initialize(process.env.NEXT_PUBLIC_GA_TRACKING_ID);

const App = ({ Component }: AppProps) => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  // Override TZKT base url if we are in ghostnet
  useEffect(() => {
    console.warn(process.env.NEXT_PUBLIC_NETWORK_TARGET);
    if (process.env.NEXT_PUBLIC_NETWORK_TARGET === 'GHOSTNET') {
      console.log('GHOSTNET !!');
      api.defaults.baseUrl = 'https://api.ghostnet.tzkt.io/';
    }
  }, []);

  return (
    <div>
      <Head>
        <link rel="shortcut icon" href="/favicon.ico" />
        <title>BATCHER</title>
      </Head>
      <Provider store={store}>
        <TezosToolkitProvider>
          <WalletProvider>
            <EventsProvider>
              <div className="flex flex-col justify-between h-screen">
                <div>
                  <NavBar
                    isMenuOpen={isMenuOpen}
                    setIsMenuOpen={setIsMenuOpen}
                  />
                  {!isMenuOpen && <Component />}
                </div>
                <Footer />
              </div>
            </EventsProvider>
          </WalletProvider>
        </TezosToolkitProvider>
      </Provider>
    </div>
  );
};

export default App;