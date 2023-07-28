import Footer from '../components/Footer';
import React, { useEffect } from 'react';
import { AppProps } from 'next/app';
import { TezosToolkitProvider } from '../contexts/tezos-toolkit';
import '../styles/globals.css';
import { Provider } from 'react-redux';
import { store } from '../src/store';
import RightContent from '../components/RightContent';
import ReactGA from 'react-ga4';
import * as api from '@tzkt/sdk-api';

import dynamic from 'next/dynamic';

type ClientOnlyProps = { children: React.JSX.Element };
const ClientOnly = (props: ClientOnlyProps) => {
  const { children } = props;

  return children;
};

const ClientOnlyProvider = dynamic(() => Promise.resolve(ClientOnly), {
  ssr: false,
});

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
    <ClientOnlyProvider>
      <Provider store={store}>
        <TezosToolkitProvider>
          <RightContent />
          <Component />
          <Footer />
        </TezosToolkitProvider>
      </Provider>
    </ClientOnlyProvider>
  );
};

export default App;