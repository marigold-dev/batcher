import { Space, Button, Menu, Dropdown, Typography } from 'antd';
import React, { useEffect } from 'react';
import { useModel } from 'umi';
import styles from '@/components/RightContent/index.less';
import { MenuOutlined, CloseOutlined } from '@ant-design/icons';
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

  const { wallet } = initialState;

  const menu = (
    <Menu
      items={[
        // {
        //   key: '0',
        //   label: <CloseOutlined className="white-color" />,
        // },
        {
          key: '1',
          label: (
            <Typography className="p-12">
              {!wallet ? 'Connect Wallet' : 'Disconnect Wallet'}
            </Typography>
          ),
          onClick: !wallet ? () => connectWallet() : () => disconnectWallet(),
        },
      ]}
    />
  );

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
    console.log('%cindex.tsx line:63 wallet', 'color: #007acc;', wallet);

    if (!wallet) {
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

  useEffect(() => {
    // connectWallet(true);
  }, []);

  return (
    <Space className={className}>
      <Button
        className="batcher-connect-wallet"
        type="primary"
        onClick={!wallet ? connectWallet : disconnectWallet}
        danger
      >
        {!wallet ? 'Connect Wallet' : 'Disconnect Wallet'}
      </Button>
      <Dropdown className="batcher-menu-outer" overlay={menu} placement="bottomLeft">
        <MenuOutlined className="batcher-menu" />
      </Dropdown>
    </Space>
  );
};
export default GlobalHeaderRight;
