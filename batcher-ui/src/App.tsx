import React from 'react';
import logo from './logo.svg';
import './App.css';
import { useState } from 'react';
import ConnectButton from './ConnectWallet';
import { TezosToolkit, WalletContract } from '@taquito/taquito';
import DisconnectButton from './DisconnectWallet';
import { Contract, ContractsService } from '@dipdup/tzkt-api';

function App() {


  const [Tezos, setTezos] = useState<TezosToolkit>(new TezosToolkit("https://jakartanet.tezos.marigold.dev"));
  const [wallet, setWallet] = useState<any>(null);
  const [userAddress, setUserAddress] = useState<string>("");
  const [userBalance, setUserBalance] = useState<number>(0);



  return (
    <div className="App">
      <header className="App-header">

  <ConnectButton
    Tezos={Tezos}
    setWallet={setWallet}
    setUserAddress={setUserAddress}
    setUserBalance={setUserBalance}
    wallet={wallet}
    />

    <DisconnectButton
    wallet={wallet}
    setUserAddress={setUserAddress}
    setUserBalance={setUserBalance}
    setWallet={setWallet}
    />




        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.tsx</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
