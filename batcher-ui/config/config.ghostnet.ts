// @ts-nocheck
import { defineConfig } from 'umi';

import defaultSettings from './defaultSettings';
import proxy from './proxy';

const { REACT_APP_ENV } = process.env;

const BATCHER_LOGO = 'https://storage.googleapis.com/marigold-public-bucket/batcher-logo.png';

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
    REACT_APP_BATCHER_URI: 'https://ghostnet.batcher.marigold.dev',
    REACT_APP_PATH_TO_BATCHER_LOGO: BATCHER_LOGO,
    REACT_APP_TEZOS_NODE_URI: 'https://ghostnet.tezos.marigold.dev',
    REACT_APP_TZKT_URI_API: 'https://api.ghostnet.tzkt.io',
    REACT_APP_BATCHER_CONTRACT_HASH: 'KT1UPMR3WkoFRJYmBBbvv4Z9bBhKYuhCx7Cq',
    GA_TRACKING_ID: 'G-2K59PEELC8',

  },
  metas: [
    {
      property: 'og:locale',
      content: 'en_US',
    },
    {
      property: 'og:title',
      content: 'Batcher DEX',
    },
    {
      property: 'og:description',
      content:
        'The aim of the batch clearing dex is to enable users to deposit tokens with the aim of being swapped at a fair price with bounded slippage and almost no impermanent loss..',
    },
    {
      property: 'og:url',
      content: 'https://batcher.marigold.dev',
    },
    {
      property: 'og:site_name',
      content: 'Batcher DEX',
    },
    {
      property: 'og:image',
      content: BATCHER_LOGO,
    },
    {
      property: 'og:image:secure_url',
      content: BATCHER_LOGO,
    },
    {
      property: 'og:image:width',
      content: '400',
    },
    {
      property: 'og:image:height',
      content: '400',
    },
    {
      name: 'twitter:card',
      content: 'summary',
    },
    {
      name: 'twitter:description',
      content:
        'The aim of the batch clearing dex is to enable users to deposit tokens with the aim of being swapped at a fair price with bounded slippage and almost no impermanent loss.',
    },
    {
      name: 'twitter:title',
      content: 'Batcher DEX',
    },
    {
      name: 'twitter:site',
      content: '@Marigold_Dev',
    },
    {
      name: 'twitter:image',
      content: BATCHER_LOGO,
    },
    {
      name: 'twitter:creator',
      content: '@Marigold_Dev',
    },
  ],
});
