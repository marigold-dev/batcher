import React from 'react';
import { AppProps } from 'next/app';
import { TezosToolkitProvider } from '../src/contexts/tezos-toolkit';
import { WalletProvider } from '../src/contexts/wallet';
import { EventsProvider } from '../src/contexts/events';
import '../styles/globals.css';
import { Provider } from 'react-redux';
import { store } from '../src/store';
import ReactGA from 'react-ga4';
import Head from 'next/head';
import { config } from '@fortawesome/fontawesome-svg-core';
import '@fortawesome/fontawesome-svg-core/styles.css';
import Root from '../src/components/Root';

config.autoAddCss = false;

process.env.NEXT_PUBLIC_GA_TRACKING_ID &&
  ReactGA.initialize(process.env.NEXT_PUBLIC_GA_TRACKING_ID);

const App = ({ Component }: AppProps) => {
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
              <Root Component={Component} />
            </EventsProvider>
          </WalletProvider>
        </TezosToolkitProvider>
      </Provider>
    </div>
  );
};

export default App;
