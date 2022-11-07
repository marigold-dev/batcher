import { defineConfig } from 'umi';

import defaultSettings from './defaultSettings';
import proxy from './proxy';

const { REACT_APP_ENV } = process.env;

export default defineConfig({
  hash: true,
  antd: {},
  dva: {
    hmr: true,
  },
  layout: {
    // https://umijs.org/zh-CN/plugins/plugin-layout
    locale: true,
    siderWidth: 208,
    ...defaultSettings,
  },
  dynamicImport: {
    loading: '@ant-design/pro-layout/es/PageLoading',
  },
  targets: {
    ie: 11,
  },
  // umi routes: https://umijs.org/docs/routing
  access: {},
  theme: {
    'root-entry-name': 'variable',
  },
  // esbuild is father build tools
  // https://umijs.org/plugins/plugin-esbuild
  esbuild: {},
  title: false,
  ignoreMomentLocale: true,
  proxy: proxy[REACT_APP_ENV || 'dev'],
  manifest: {
    basePath: '/',
  },
  // Fast Refresh 热更新
  fastRefresh: {},
  nodeModulesTransform: { type: 'none' },
  mfsu: {},
  webpack5: {},
  exportStatic: {},
  favicon:
    'https://uploads-ssl.webflow.com/616ab4741d375d1642c19027/617952f8510cfc45cbf09312_Favicon(3)(1).png',
  define: {
    REACT_APP_NETWORK_TARGET: 'GHOSTNET',
    REACT_APP_TEZOS_NODE_URI: 'https://ghostnet.ecadinfra.com',
    REACT_APP_TZKT_URI_API: 'https://api.ghostnet.tzkt.io',
    REACT_APP_BATCHER_CONTRACT_HASH: 'KT1G7ziTpUgXQR9QymGj348jM5B8KdZgBp1B',
    REACT_APP_TZBTC_HASH: 'KT1MQJKqrB982V7hqDo3MjCV2aCS6Dyt5PLz',
    REACT_APP_USDT_HASH: 'KT1H9hKtcqcMHuCoaisu8Qy7wutoUPFELcLm',
  },
});
