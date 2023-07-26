import Footer from '../components/Footer';
import React from 'react';
import { AppProps } from 'next/app';
import { TezosToolkitProvider } from '../contexts/tezos-toolkit';
import '../styles/globals.css';
import { Provider } from 'react-redux';
import { store } from 'src/store';
import RightContent from '../components/RightContent';
import ReactGA from 'react-ga4';

ReactGA.initialize(process.env.REACT_APP_GA_TRACKING_ID);

export default ({ Component }: AppProps) => {
  return (
    <Provider store={store}>
      <TezosToolkitProvider>
        <RightContent />
        <Component />
        <Footer />
      </TezosToolkitProvider>
    </Provider>
  );
};
