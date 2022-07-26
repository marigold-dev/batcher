import { Space, Button, Dropdown, Typography, MenuProps } from 'antd';
import React, { useEffect } from 'react';
import { useModel } from 'umi';
import styles from '@/components/RightContent/index.less';
import { MenuOutlined } from '@ant-design/icons';
import { TezosToolkit } from '@taquito/taquito';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { NetworkType } from '@/extra_utils/types';
import '@/components/RightContent/index.less';

export type SiderTheme = 'light' | 'dark';

const GlobalHeaderRight: React.FC = () => {
  const { initialState, setInitialState } = useModel('@@initialState');

  if (!initialState || !initialState.settings) {
    return null;
  }

  const { navTheme, layout } = initialState.settings;
  let className = styles.right;

  if ((navTheme === 'dark' && layout === 'top') || layout === 'mix') {
    className = `${styles.right}  ${styles.dark}`;
  }

  const { userAddress } = initialState;

  const items: MenuProps['items'] = [
    {
      key: '1',
      label: (
        <Typography className="p-12">
          {!userAddress ? 'Connect Wallet' : 'Disconnect Wallet'}
        </Typography>
      ),
    },
  ];

  const menuProps = {
    items,
    onClick: !userAddress ? () => connectWallet() : () => disconnectWallet(),
  };

  const Tezos = new TezosToolkit(REACT_APP_TEZOS_NODE_URI);

  const getNetworkType = () => {
    const network = REACT_APP_NETWORK_TARGET;
    if (network?.includes('GHOSTNET')) {
      return NetworkType.GHOSTNET;
    } else {
      return NetworkType.KATHMANDUNET;
    }
  };

  const connectWallet = async () => {
    if (!userAddress) {
      const updatedWallet = new BeaconWallet({
        name: 'batcher',
        preferredNetwork: getNetworkType(),
      });
      await updatedWallet.requestPermissions({
        network: {
          type: getNetworkType(),
          rpcUrl: REACT_APP_TEZOS_NODE_URI,
        },
      });

      Tezos.setWalletProvider(updatedWallet);
      const activeAccount = await updatedWallet.client.getActiveAccount();
      const userAddress = activeAccount ? await updatedWallet.getPKH() : null;
      setInitialState({ ...initialState, wallet: updatedWallet, userAddress });
    }
  };

  const disconnectWallet = async () => {
    setInitialState({ ...initialState, wallet: null, userAddress: null });
  };

  const scrollToTop = () => {
    window.scrollTo(0, 0);
  };

  useEffect(() => {
    // connectWallet(true);
  }, []);

  return (
    <div>
      <Space className={className}>
        <Button
          className="batcher-connect-wallet"
          type="primary"
          onClick={!userAddress ? connectWallet : disconnectWallet}
          danger
        >
          {!userAddress ? 'Connect Wallet' : 'Disconnect Wallet'}
        </Button>
        <div onClick={scrollToTop}>
          <Dropdown className="batcher-menu-outer" menu={menuProps} placement="bottomLeft">
            <MenuOutlined className="batcher-menu" />
          </Dropdown>
        </div>
      </Space>
    </div>
  );
};
export default GlobalHeaderRight;
