import Footer from '../components/Footer';
import React from 'react';
// import { Spin, Image } from 'antd';
// import MarigoldLogo from '../img/marigold-logo.png';
// import { TezosToolkit } from '@taquito/taquito';
import { AppProps } from 'next/app';
import { AppProvider } from '../contexts';
import { TezosToolkitProvider } from '../contexts/tezos-toolkit';

// Spin.setDefaultIndicator(<Image src={MarigoldLogo} />);

// export const layout: RunTimeLayoutConfig = ({ initialState, setInitialState }) => {
//   return {
//     rightContentRender: () => <RightContent />,
//     disableContentMargin: false,
//     waterMarkProps: {
//       content: initialState?.currentUser?.name,
//     },
//     footerRender: () => <Footer />,
//     menuHeaderRender: undefined,
//     ...initialState?.settings,
//     childrenRender: () => {
//       return <Main />;
//     },
//   };
// };

export default ({ Component }: AppProps) => {
  return (
    <div>
      <AppProvider>
        <TezosToolkitProvider>
          <Component />
          {/* <Footer /> */}
        </TezosToolkitProvider>
      </AppProvider>
    </div>
  );
};
