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
  logo: 'https://s3-alpha-sig.figma.com/img/8ef9/ebc0/4711872c139e475b6a3fa5870707eb3a?Expires=1667174400&Signature=M0zlGc5wdH2IhUXeUQqlUuoAbnfJgBHwFimQ2L3irsr03yU~kDtHysMW5HlzlIZQqfMklKCti9-MV~tVuVXSpVDlo2T6e8cCSrFA-~HiuiehnFTPKSBkPHwjB3hGSE5yDlfsU0R82bs98TvjqCb3SreV6apOLNOEMcMrOoItl3s8av72OjZeEy1XIGDH8ByBVjAGtuV8MDk~dbvOEhm7zkSrxXfw-g1EeUNnT1vsANKDOZtiTBJetzOUVxUt6sgKB7ossX6QybjAgm5eYe781~uewIAZtOpAvLFeOHG2nVuJ7bu7Be9CRSjyyF-fZbF0aCxCUQeRjLOTxXYugq2qkQ__&Key-Pair-Id=APKAINTVSUGEWH5XD5UA',
  iconfontUrl: '',
  disableMobile: true,
};

export default Settings;
