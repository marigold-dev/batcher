import { Space, Button, Dropdown, Typography, MenuProps } from 'antd';
import React, { useContext, useEffect, useState } from 'react';
import { MenuOutlined } from '@ant-design/icons';
import { TezosToolkit } from '@taquito/taquito';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { getNetworkType } from '../../extra_utils/utils';
// import './index.less';
import { connection } from '../../extra_utils/webSocketUtils';
import { AppDispatchContext, AppStateContext } from '../../contexts';

export type SiderTheme = 'light' | 'dark';

const GlobalHeaderRight: React.FC = () => {
  const state = useContext(AppStateContext);
  const dispatch = useContext(AppDispatchContext);
  const tezosNodeUri = process.env.REACT_APP_TEZOS_NODE_URI;

  if (!tezosNodeUri) return; // TODO: improve this

  const tezos = new TezosToolkit(tezosNodeUri);
  if (!state || !state.settings) {
    return null;
  }

  const { navTheme, layout } = state.settings;
  let className = '.right';

  if ((navTheme === 'dark' && layout === 'top') || layout === 'mix') {
    className = `.right .dark`; //TODO: rewrite this
  }

  const connectCaption = 'Connect Wallet';
  const connectingCaption = 'Connecting...';
  const disconnectCaption = 'Disconnect Wallet';
  const disconnectingCaption = 'Disconnecting...';
  const [caption, setCaption] = useState<string>(connectCaption);

  const items: MenuProps['items'] = [
    {
      key: '1',
      label: <Typography className="p-12">{caption}</Typography>,
    },
  ];

  const menuProps = {
    items,
    onClick: !state.userAddress ? () => connectWallet() : () => disconnectWallet(),
  };

  const connectWallet = async () => {
    console.info('=== STATE ===  state change check ', state);
    if (!state.userAddress) {
      setCaption(connectingCaption);
      const wallet = new BeaconWallet({
        name: 'batcher',
        preferredNetwork: getNetworkType(),
      });
      await wallet.requestPermissions({
        network: {
          type: getNetworkType(),
          rpcUrl: tezosNodeUri,
        },
      });

      tezos.setWalletProvider(wallet);
      const activeAccount = await wallet.client.getActiveAccount();
      const userAddress = activeAccount ? await wallet.getPKH() : null;
      let updatedState = {
        ...state,
        wallet: wallet,
        userAddress: userAddress,
        userAccount: activeAccount,
      };

      setCaption(disconnectCaption);
      //      localStorage.setItem("state", JSON.stringify(updatedState));
      console.log('localstroage - after connect', localStorage);
      dispatch(updatedState); // TODO: Work on app state
      console.log('Setting initialState', updatedState);
    }
  };

  const disconnectWallet = async () => {
    console.info('Disconnecting wallet');
    setCaption(disconnectingCaption);
    await connection.stop();
    try {
      if (!state.wallet) {
        throw new Error('Not wallet !');
      }
      // await state.wallet.clearActiveAccount();  // TODO: find a way to fix this
    } catch (error) {
      console.error(error);
    }
    let updatedState = { ...state, wallet: null, userAddress: null, userAccount: null };
    localStorage.setItem('state', JSON.stringify(updatedState));
    dispatch(updatedState); // TODO: Work on app state
    setCaption(connectCaption);
  };

  const scrollToTop = () => {
    window.scrollTo(0, 0);
  };

  const newWallet = () => {
    return new BeaconWallet({
      name: 'batcher',
      preferredNetwork: getNetworkType(),
    });
  };

  useEffect(() => {
    (async () => {
      try {
        setCaption(connectCaption);
        //        let localstate = JSON.parse(localStorage.getItem("state"));
        let wallet = newWallet();

        setCaption(connectingCaption);
        tezos.setWalletProvider(wallet);
        const activeAccount = await wallet.client.getActiveAccount();
        if (activeAccount) {
          console.info('=== STATE ===  no dep check - active account ', activeAccount);
          const userAddress = await wallet.getPKH();
          let updatedState = {
            ...state,
            wallet: wallet,
            userAddress: userAddress,
            userAccount: activeAccount,
          };
          // localStorage.setItem("state", JSON.stringify(updatedState));
          dispatch(updatedState); // TODO: Work on app state
          setCaption(disconnectCaption);
        } else {
          setCaption(connectCaption);
        }
      } catch (error) {
        setCaption(connectCaption);
        console.error(error);
      }
    })();
  }, []);
  return (
    <div>
      <Space className={className}>
        <Button
          className="batcher-connect-wallet"
          type="primary"
          onClick={!state.userAddress ? connectWallet : disconnectWallet}
          danger
        >
          {caption}
        </Button>
        <div onClick={scrollToTop}>
          {/* <Dropdown className="batcher-menu-outer" menu={menuProps} placement="bottomLeft">
            <MenuOutlined className="batcher-menu" />
          </Dropdown> */}
        </div>
      </Space>
    </div>
  );
};
export default GlobalHeaderRight;
