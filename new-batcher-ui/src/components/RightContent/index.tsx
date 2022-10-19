import { Space, Button, Menu, Dropdown, Typography } from 'antd';
import React, { useEffect } from 'react';
import { useModel, FormattedMessage } from 'umi';
import styles from './index.less';
import { MenuOutlined } from '@ant-design/icons';
import { TezosToolkit } from '@taquito/taquito';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { NetworkType } from '@/extra_utils/types';

export type SiderTheme = 'light' | 'dark';

const menu = (
  <Menu
    items={[
      {
        key: '1',
        label: <Typography>Connect Wallet</Typography>,
      },
      {
        key: '2',
        label: <Typography>Order books</Typography>,
      },
      {
        key: '3',
        label: <Typography>Redeem holdings</Typography>,
      },
    ]}
  />
);

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
  console.log(process.env);

  const Tezos = new TezosToolkit(process.env['REACT_APP_TEZOS_NODE_URI']!);

  const getNetworkType = () => {
    const network = process.env['REACT_APP_NETWORK_TARGET'];
    if (network?.includes('KATHMANDUNET')) {
      return NetworkType.KATHMANDUNET;
    } else if (network?.includes('JAKARTANET')) {
      return NetworkType.JAKARTANET;
    } else {
      console.log('%cindex.tsx line:55 NetworkType.GHOSTNET', 'color: #007acc;', NetworkType);
      return NetworkType.GHOSTNET;
    }
  };

  const connectWallet = async (connectionState: boolean) => {
    console.log('%cindex.tsx line:63 wallet', 'color: #007acc;', wallet);

    if (!wallet) {
      const updatedWallet = new BeaconWallet({
        name: 'batcher',
        preferredNetwork: getNetworkType(),
      });
      if (!connectionState) {
        await updatedWallet.requestPermissions({
          network: {
            type: getNetworkType(),
            rpcUrl: process.env['REACT_APP_TEZOS_NODE_URI']!,
          },
        });
      }

      Tezos.setWalletProvider(updatedWallet);
      const activeAccount = await updatedWallet.client.getActiveAccount();
      const userAddress = activeAccount ? await updatedWallet.getPKH() : null;
      setInitialState({ ...initialState, wallet: updatedWallet, userAddress });
    }
  };

  useEffect(() => {
    connectWallet(true);
  }, []);

  return (
    <Space className={className}>
      <Button
        className="batcher-connect-wallet"
        type="primary"
        onClick={() => connectWallet(false)}
        danger
      >
        <FormattedMessage id="pages.searchTable.batchDeletion" defaultMessage="Connect Wallet" />
      </Button>
      <Dropdown overlay={menu} placement="bottomLeft">
        <MenuOutlined className="batcher-menu" />
      </Dropdown>
    </Space>
  );
};
export default GlobalHeaderRight;
