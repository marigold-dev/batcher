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
  define: {
    REACT_APP_NETWORK_TARGET: 'GHOSTNET',
    REACT_APP_TEZOS_NODE_URI: 'https://ghostnet.tezos.marigold.dev',
    REACT_APP_TZKT_URI_API: 'https://api.ghostnet.tzkt.io',
    REACT_APP_BATCHER_CONTRACT_HASH: 'KT1Q94T4yntfYx2X2zVQTNuAtNbdppzFRRhE',
    REACT_APP_TZBTC_HASH: 'KT1XLyXAe5FWMHnoWa98xZqgDUyyRms2B3tG',
    REACT_APP_USDT_HASH: 'KT1H9hKtcqcMHuCoaisu8Qy7wutoUPFELcLm',
  },
});
