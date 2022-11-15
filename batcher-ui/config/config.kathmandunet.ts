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
    REACT_APP_NETWORK_TARGET: 'KATHMANDUNET',
    REACT_APP_BATCHER_URI: 'https://kathmandunet.batcher.marigold.dev',
    REACT_APP_PATH_TO_BATCHER_LOGO:
      'https://storage.googleapis.com/marigold-public-bucket/batcher-logo.png',
    REACT_APP_TEZOS_NODE_URI: 'https://kathmandunet.tezos.marigold.dev',
    REACT_APP_TZKT_URI_API: 'https://api.kathmandunet.tzkt.io',
    REACT_APP_BATCHER_CONTRACT_HASH: 'KT1CRv12p9vk1ud5VMvrRMKmsm6iyYjbfF6j',
    REACT_APP_TZBTC_HASH: 'KT1FRyR3ohQ59N54BJMg9KjDUGh4z5hWuYab',
    REACT_APP_USDT_HASH: 'KT1QVV45Rj9r6WbjLczoDxViP9s1JpiCsxVF',
  },
});
