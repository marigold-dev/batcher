import { Space, Button, Dropdown, Typography, MenuProps } from 'antd';
import React, { useEffect } from 'react';
import { useModel } from 'umi';
import styles from '@/components/RightContent/index.less';
import { MenuOutlined } from '@ant-design/icons';
import { TezosToolkit } from '@taquito/taquito';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { getNetworkType } from '@/extra_utils/utils';
import '@/components/RightContent/index.less';
import { connection } from '@/extra_utils/webSocketUtils';
import { RightContentProps } from '@/extra_utils/types';

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

  const { storedUserAddress } = initialState;

  const items: MenuProps['items'] = [
    {
      key: '1',
      label: (
        <Typography className="p-12">
          {!storedUserAddress ? 'Connect Wallet' : 'Disconnect Wallet'}
        </Typography>
      ),
    },
  ];

  const menuProps = {
    items,
    onClick: !storedUserAddress ? () => connectWallet() : () => disconnectWallet(),
  };

  const Tezos = new TezosToolkit(REACT_APP_TEZOS_NODE_URI);

  const connectWallet = async () => {
    if (!storedUserAddress) {
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
      const userAddressFromWallet = activeAccount ? await updatedWallet.getPKH() : null;
      setInitialState({ ...initialState, wallet: updatedWallet, userAddressFromWallet });
      localStorage.setItem('storedUserAddress', userAddressFromWallet);
    }
  };

  const disconnectWallet = async () => {
    await connection.stop();
    setInitialState({ ...initialState, wallet: null, userAddress: null });
    localStorage.removeItem('storedUserAddress');
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
          onClick={!storedUserAddress ? connectWallet : disconnectWallet}
          danger
        >
          {!storedUserAddress ? 'Connect Wallet' : 'Disconnect Wallet'}
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
