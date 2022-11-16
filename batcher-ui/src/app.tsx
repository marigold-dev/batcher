import Footer from '@/components/Footer';
import RightContent from '@/components/RightContent';
import { PageLoading } from '@ant-design/pro-components';
import type { RunTimeLayoutConfig } from 'umi';
import defaultSettings from '../config/defaultSettings';
import Main from './pages/Main';
import { Spin, Image } from 'antd';
import MarigoldLogo from '../img/marigold-logo.png';

Spin.setDefaultIndicator(<Image src={MarigoldLogo} />);

export const initialStateConfig = {
  loading: <PageLoading />,
};

export async function getInitialState(): Promise<any> {
  return {
    wallet: null,
    userAddress: localStorage.getItem('address') ?? null,
    settings: defaultSettings,
  };
}

export const layout: RunTimeLayoutConfig = ({ initialState, setInitialState }) => {
  return {
    rightContentRender: () => <RightContent />,
    disableContentMargin: false,
    waterMarkProps: {
      content: initialState?.currentUser?.name,
    },
    footerRender: () => <Footer />,
    menuHeaderRender: undefined,
    ...initialState?.settings,
    childrenRender: () => {
      return <Main />;
    },
  };
};
