declare module 'slash2';
declare module '*.css';
declare module '*.less';
declare module '*.scss';
declare module '*.sass';
declare module '*.svg';
declare module '*.png';
declare module '*.jpg';
declare module '*.jpeg';
declare module '*.gif';
declare module '*.bmp';
declare module '*.tiff';
declare module 'omit.js';
declare module 'numeral';
declare module '@antv/data-set';
declare module 'mockjs';
declare module 'react-fittext';
declare module 'bizcharts-plugin-slider';



declare global {
  // eslint-disable-next-line no-unused-vars
  namespace NodeJS {
    // eslint-disable-next-line no-unused-vars
    interface ProcessEnv {
      REACT_APP_ENV: 'test' | 'dev' | 'pre' | false;
      NEXT_PUBLIC_NETWORK_TARGET: string;
      NEXT_PUBLIC_TEZOS_NODE_URI: string;
      NEXT_PUBLIC_TZKT_URI_API: string;
      NEXT_PUBLIC_BATCHER_CONTRACT_HASH: string;
      REACT_APP_TZBTC_HASH: string;
      REACT_APP_USDT_HASH: string;
      NEXT_PUBLIC_BATCHER_URI: string;
      NEXT_PUBLIC_PATH_TO_BATCHER_LOGO: string;
      NEXT_PUBLIC_GA_TRACKING_ID: string;
      NEXT_PUBLIC_LOCAL_STORAGE_KEY_STATE: string;
    }
  }
}