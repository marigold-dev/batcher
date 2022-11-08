import { Space, Button, Dropdown, Typography, MenuProps } from 'antd';
import React, { useEffect } from 'react';
import { useModel } from 'umi';
import styles from '@/components/RightContent/index.less';
import { MenuOutlined } from '@ant-design/icons';
import { TezosToolkit } from '@taquito/taquito';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { NetworkType } from '@/extra_utils/types';
import '@/components/RightContent/index.less';
import { MetaTags } from 'react-meta-tags';

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

  const items: MenuProps['items'] = [
    {
      key: '1',
      label: (
        <Typography className="p-12">{!wallet ? 'Connect Wallet' : 'Disconnect Wallet'}</Typography>
      ),
    },
  ];

  const menuProps = {
    items,
    onClick: !wallet ? () => connectWallet() : () => disconnectWallet(),
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

  const site_uri = REACT_APP_BATCHER_URI;
  const path_to_logo = REACT_APP_PATH_TO_BATCHER_LOGO;

  const connectWallet = async () => {
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

  const scrollToTop = () => {
    window.scrollTo(0, 0);
  };

  useEffect(() => {
    // connectWallet(true);
  }, []);

  return (
  <div>
    <MetaTags>
     <meta property="og:locale" content="en_US"/>
     <meta property="og:title" content="Batcher DEX"/>
     <meta property="og:description"
    content="The aim of the batch clearing dex is to enable users to deposit tokens with the aim of being swapped at a fair price with bounded slippage and almost no impermanent loss.."/>
     <meta property="og:url" content={ site_uri }/>
     <meta property="og:site_name" content="Batcher"/>
     <meta property="og:image" content={ path_to_logo }/>
     <meta property="og:image:secure_url" content={ path_to_logo }/>
     <meta property="og:image:width" content="400"/>
     <meta property="og:image:height" content="400" />
     <meta name=" twitter:card" content="summary" />
     <meta name="twitter:description"
    content="The aim of the batch clearing dex is to enable users to deposit tokens with the aim of being swapped at a fair price with bounded slippage and almost no impermanent loss." />
     <meta name="twitter:title" content="Batcher DEX"/>
     <meta name="twitter:site" content="@Marigold_Dev"/>
     <meta name="twitter:image" content={ path_to_logo }/>
     <meta name="twitter:creator" content="@Marigold_Dev"/>
     </MetaTags>
    <Space className={className}>
      <Button
        className="batcher-connect-wallet"
        type="primary"
        onClick={!wallet ? connectWallet : disconnectWallet}
        danger
      >
        {!wallet ? 'Connect Wallet' : 'Disconnect Wallet'}
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
