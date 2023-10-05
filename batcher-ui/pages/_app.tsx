<<<<<<< HEAD
import Footer from '../src/components/Footer';
import React, { useEffect, useState } from 'react';
=======
import React from 'react';
>>>>>>> release-ghostnet
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
import Toast from 'src/components/Toast';

config.autoAddCss = false;

process.env.NEXT_PUBLIC_GA_TRACKING_ID &&
  ReactGA.initialize(process.env.NEXT_PUBLIC_GA_TRACKING_ID);

const App = ({ Component }: AppProps) => {
  return (
    <div>
      <Head>
        <link rel="shortcut icon" href="/favicon.ico" />
        <title>BATCHER</title>
        <meta property="og:locale" content="en_US" />
        <meta property="og:title" content="Batcher DEX" />
        <meta
          property="og:description"
          content="The aim of the batch clearing dex is to enable users to deposit tokens with the aim of being swapped at a fair price with bounded slippage and almost no impermanent loss.."
        />
        <meta property="og:url" content={process.env.NEXT_PUBLIC_BATCHER_URI} />
        <meta property="og:site_name" content="Batcher DEX" />
        <meta
          property="og:image"
          content={process.env.NEXT_PUBLIC_PATH_TO_BATCHER_LOGO}
        />
        <meta property="twitter:card" content="summary" />
        <meta
          property="twitter:description"
          content="The aim of the batch clearing dex is to enable users to deposit tokens with the aim of being swapped at a fair price with bounded slippage and almost no impermanent loss.."
        />
        <meta property="twitter:title" content="Batcher DEX" />
        <meta property="twitter:site" content="@Marigold_Dev" />
        <meta property="twitter:creator" content="@Marigold_Dev" />
        <meta
          property="twitter:image"
          content={process.env.NEXT_PUBLIC_PATH_TO_BATCHER_LOGO}
        />
      </Head>
      <Provider store={store}>
        <TezosToolkitProvider>
          <WalletProvider>
            <EventsProvider>
              <Root Component={Component} />
              <Toast />
            </EventsProvider>
          </WalletProvider>
        </TezosToolkitProvider>
      </Provider>
    </div>
  );
};

export default App;
