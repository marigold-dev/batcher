import Footer from '@/components/Footer';
import React, { useState, useEffect } from 'react';
import RightContent from '@/components/RightContent';
import { AccountInfo } from '@airgap/beacon-sdk';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { PageLoading } from '@ant-design/pro-components';
import type { RunTimeLayoutConfig } from 'umi';
import defaultSettings from '../config/defaultSettings';
import Main from './pages/Main';
import { Spin, Image } from 'antd';
import MarigoldLogo from '../img/marigold-logo.png';
import { TezosToolkit } from '@taquito/taquito';
import ReactGA from "react-ga4";
Spin.setDefaultIndicator(<Image src={MarigoldLogo} />);

ReactGA.initialize(GA_TRACKING_ID);

export const initialStateConfig = {
  loading: <PageLoading />,
};

export async function getInitialState(): Promise<any> {
  return {
    wallet: null,
    userAddress: null,
    userAccount: null,
    settings: defaultSettings,
  };
}

export const layout: RunTimeLayoutConfig = ({ initialState, setInitialState }) => {
  return {
    rightContentRender: () => <RightContent />,
    disableContentMargin: false,
    waterMarkProps: {
      content: initialState?.currentUser?.name,
    },
    footerRender: () => <Footer />,
    menuHeaderRender: undefined,
    ...initialState?.settings,
    childrenRender: () => {
      return <Main />;
    },
  };
};
