import { TezosToolkit } from "@taquito/taquito";
import {
  NetworkType
} from "@airgap/beacon-sdk";
import { Dispatch, SetStateAction } from "react";
import { BeaconWallet } from "@taquito/beacon-wallet";
import './App.css';
import toast, { Toaster } from 'react-hot-toast';
import {
  Button
} from "reactstrap";

interface ButtonProps {
  wallet: BeaconWallet | null;
  setUserAddress: Dispatch<SetStateAction<string>>;
  setUserBalance: Dispatch<SetStateAction<number>>;
  userAddress : string;
  setWallet: Dispatch<SetStateAction<any>>;
}

const DisconnectButton = ({
  wallet,
  setUserAddress,
  setUserBalance,
  userAddress,
  setWallet,
}: ButtonProps): JSX.Element => {
  const disconnectWallet = async (): Promise<void> => {
    setUserAddress("No Wallet Connected");
    setUserBalance(0);
    setWallet(null);
    console.log("disconnecting wallet");
    if (wallet) {
      await wallet.client.removeAllAccounts();
      await wallet.client.removeAllPeers();
      await wallet.client.destroy();
    }
  };

  return (
      <Button active={ userAddress == "" ? false : true } className="btn-danger" size="sm" onClick={disconnectWallet}>
        Disconnect
      </Button>
  );
};

export default DisconnectButton;
