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

// preview.pro.ant.design only do not use in your production ;
// preview.pro.ant.design Dedicated environment variable, please do not use it in your project.
declare let ANT_DESIGN_PRO_ONLY_DO_NOT_USE_IN_YOUR_PRODUCTION:
  | 'site'
  | undefined;

declare const REACT_APP_ENV: 'test' | 'dev' | 'pre' | false;

declare const REACT_APP_NETWORK_TARGET;
declare const REACT_APP_TEZOS_NODE_URI;
declare const REACT_APP_TZKT_URI_API;
declare const REACT_APP_BATCHER_CONTRACT_HASH;
declare const REACT_APP_TZBTC_HASH;
declare const REACT_APP_USDT_HASH;
declare const REACT_APP_BATCHER_URI;
declare const REACT_APP_PATH_TO_BATCHER_LOGO;
declare const REACT_APP_GA_TRACKING_ID;
declare const REACT_APP_LOCAL_STORAGE_KEY_STATE;
