import { Settings as LayoutSettings } from '@ant-design/pro-components';

const Settings: LayoutSettings & {
  pwa?: boolean;
  logo?: string;
  disableMobile?: boolean;
} = {
  navTheme: 'dark',
  // 拂晓蓝
  primaryColor: 'black',
  layout: 'top',
  contentWidth: 'Fluid',
  fixedHeader: true,
  fixSiderbar: true,
  colorWeak: false,
  title: 'BATCHER',
  pwa: false,
  logo: 'https://storage.cloud.google.com/marigold-stuff/batcher-logo.png?authuser=1',
  iconfontUrl: '',
  disableMobile: true,
};

export default Settings;
