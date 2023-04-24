import { Space, Button, Dropdown, Typography, MenuProps } from 'antd';
import React, { useEffect, useState } from 'react';
import { useModel } from 'umi';
import styles from '@/components/RightContent/index.less';
import { MenuOutlined } from '@ant-design/icons';
import { TezosToolkit } from '@taquito/taquito';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { getNetworkType } from '@/extra_utils/utils';
import '@/components/RightContent/index.less';
import { connection } from '@/extra_utils/webSocketUtils';
import { LocalStorage } from "@airgap/beacon-sdk";

export type SiderTheme = 'light' | 'dark';



const GlobalHeaderRight: React.FC = () => {
  const { initialState, setInitialState } = useModel('@@initialState');
  const tezos = new TezosToolkit(REACT_APP_TEZOS_NODE_URI);
  if (!initialState || !initialState.settings) {
    return null;
  }

  const { navTheme, layout } = initialState.settings;
  let className = styles.right;

  if ((navTheme === 'dark' && layout === 'top') || layout === 'mix') {
    className = `${styles.right}  ${styles.dark}`;
  }

const connectCaption = "Connect Wallet";
const connectingCaption = "Connecting...";
const disconnectCaption = "Disconnect Wallet";
const disconnectingCaption = "Disconnecting...";
const [ caption, setCaption ] = useState<string>(connectCaption);

  const items: MenuProps['items'] = [
    {
      key: '1',
      label: (
        <Typography className="p-12">
          { caption }
        </Typography>
      ),
    },
  ];

  const menuProps = {
    items,
    onClick: !initialState.userAddress ? () => connectWallet() : () => disconnectWallet(),
  };


  const connectWallet = async () => {
      console.info("=== STATE ===  state change check ", initialState);
    if (!initialState.userAddress) {
      setCaption(connectingCaption);
      const wallet = new BeaconWallet({
        name: 'batcher',
        preferredNetwork: getNetworkType(),
      });
      await wallet.requestPermissions({
        network: {
          type: getNetworkType(),
          rpcUrl: REACT_APP_TEZOS_NODE_URI,
        },
      });

      tezos.setWalletProvider(wallet);
      const activeAccount = await wallet.client.getActiveAccount();
      const userAddress = activeAccount ? await wallet.getPKH() : null;
      let updatedState = { ...initialState, wallet: wallet, userAddress: userAddress, userAccount: activeAccount};
      
      setCaption(disconnectCaption);
      localStorage.setItem("state", JSON.stringify(updatedState));
      console.log("localstroage - after connect", localStorage);
      setInitialState(updatedState);
      console.log("Setting initialState", updatedState);
    }
  };

  const disconnectWallet = async () => {
    console.info("Disconnecting wallet");
    setCaption(disconnectingCaption);
    await connection.stop();
    try{
    await initialState.wallet.clearActiveAccount();
    } catch (error) {
      console.error(error);
    }
    let updatedState = { ...initialState, wallet: null, userAddress: null, userAccount:null };
    localStorage.setItem("state", JSON.stringify(updatedState));
    setInitialState(updatedState);
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

      setCaption(connectCaption);
      let localstate = JSON.parse(localStorage.getItem("state"));
      let state = localstate !== null ? localstate : initialState
      let wallet = newWallet();

      try {

        setCaption(connectingCaption);
        tezos.setWalletProvider(wallet);
        const activeAccount = await wallet.client.getActiveAccount();
        if (activeAccount) {
          console.info("=== STATE ===  no dep check - active account ", activeAccount);
          const userAddress = await wallet.getPKH();
          let updatedState = { ...state, wallet: wallet, userAddress: userAddress,  userAccount: activeAccount, };
          localStorage.setItem("state", JSON.stringify(updatedState));
          setInitialState(updatedState);
          setCaption(disconnectCaption);

        }
      } catch (error) {
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
          onClick={!initialState.userAddress ? connectWallet : disconnectWallet}
          danger
        >
          { caption }
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
