import { Dispatch, SetStateAction } from "react";
import { BeaconWallet } from "@taquito/beacon-wallet";
import './App.css';
import toast from 'react-hot-toast';
import {
  Button
} from "reactstrap";

interface ButtonProps {
  wallet: BeaconWallet | null;
  setUserAddress: Dispatch<SetStateAction<string>>;
  userAddress : string;
  setWallet: Dispatch<SetStateAction<any>>;
}

const DisconnectButton = ({
  wallet,
  setUserAddress,
  userAddress,
  setWallet,
}: ButtonProps): JSX.Element => {
  const disconnectWallet = async (): Promise<void> => {
    setUserAddress("No Wallet Connected");
    setWallet(null);
    toast.success('Wallet for address ' + userAddress + ' disconnected')
    if (wallet) {
      await wallet.client.removeAllAccounts();
      await wallet.client.removeAllPeers();
      await wallet.client.destroy();
    }
  };

  return (
      <Button block active={ userAddress == "" ? false : true } className="btn-success" size="sm" onClick={disconnectWallet}>
        Disconnect
      </Button>
  );
};

export default DisconnectButton;
