import { Dispatch, SetStateAction, useState, useEffect } from "react";
import { TezosToolkit } from "@taquito/taquito";
import { BeaconWallet } from "@taquito/beacon-wallet";
import './App.css';
import toast from 'react-hot-toast';
import {
  NetworkType
} from "@airgap/beacon-sdk";

// reactstrap components
import {
  Button
} from "reactstrap";
import { isThisTypeNode } from "typescript";

type ButtonProps = {
  Tezos: TezosToolkit;
  setWallet: Dispatch<SetStateAction<any>>;
  setUserAddress: Dispatch<SetStateAction<string>>;
  userAddress: string;
  wallet: BeaconWallet;
};

const ConnectButton = ({
  Tezos,
  setWallet,
  setUserAddress,
  userAddress,
  wallet
}: ButtonProps): JSX.Element => {

  const setup = async (userAddress: string): Promise<void> => {
    setUserAddress(userAddress);
    toast.success('Wallet for address ' + userAddress + ' connected')
  };

  const getNetworkType = () => {
    const network = process.env["TEZOS_NODE_URI"];
    if(network?.includes("KATHMANDUNET"))
     { 
       return NetworkType.KATHMANDUNET; 
      }
    else if(network?.includes("JAKARTANET")) {
       return NetworkType.JAKARTANET;
      }
    else 
     {
        return NetworkType.GHOSTNET;
      }
  }

  const connectWallet = async (): Promise<void> => {
    try {
      if(!wallet) await createWallet();
      await wallet.requestPermissions({
        network: {
          type: getNetworkType() ,
          rpcUrl: process.env["TEZOS_NODE_URI"]!
        }
      });
      // gets user's address
      const userAddress = await wallet.getPKH();
      await setup(userAddress);
    } catch (error) {
      console.log(error);
    }
  };

  const createWallet = async() => {
    // creates a wallet instance if not exists
    if(!wallet){
      wallet = new BeaconWallet({
      name: "batcher",
      preferredNetwork: NetworkType.GHOSTNET
    });}
    Tezos.setWalletProvider(wallet);
    setWallet(wallet);
    // checks if wallet was connected before
    const activeAccount = await wallet.client.getActiveAccount();
    if (activeAccount) {
      const userAddress = await wallet.getPKH();
      await setup(userAddress);
    }
  }

  useEffect(() => {
    (async () => createWallet())();
  }, []);

  return (
      <Button block active={userAddress == "" ? true : false } className="btn-success" size="sm" onClick={connectWallet}>
          Connect
      </Button>
  );
};

export default ConnectButton;
