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
  logo: 'https://lh3.googleusercontent.com/drive-viewer/AJc5JmQGF2FV1rgeAfnXwcK6MX7y99zqRd5P7Fjr0Xe3hvAoLP1deg_TJPag4PNJ1ZQEe_uMwjHv8Ow=w800-h1722',
  iconfontUrl: '',
  disableMobile: true,
};

export default Settings;
