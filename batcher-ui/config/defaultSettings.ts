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
  logo: 'https://storage.googleapis.com/marigold-public-bucket/batcher-logo.png',
  iconfontUrl: '',
  disableMobile: true,
};

export default Settings;
