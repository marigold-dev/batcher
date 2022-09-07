import { TezosToolkit } from "@taquito/taquito";
import {
  NetworkType
} from "@airgap/beacon-sdk";
import { Dispatch, SetStateAction } from "react";
import { BeaconWallet } from "@taquito/beacon-wallet";
import './App.css';
import {
  Button
} from "reactstrap";

interface ButtonProps {
  wallet: BeaconWallet | null;
  setUserAddress: Dispatch<SetStateAction<string>>;
  setUserBalance: Dispatch<SetStateAction<number>>;
  setWallet: Dispatch<SetStateAction<any>>;
}

const DisconnectButton = ({
  wallet,
  setUserAddress,
  setUserBalance,
  setWallet,
}: ButtonProps): JSX.Element => {
  const disconnectWallet = async (): Promise<void> => {
    setUserAddress("");
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
      <Button className="btn-danger" color="primary" onClick={disconnectWallet}>
        Disconnect wallet
      </Button>
  );
};

export default DisconnectButton;
