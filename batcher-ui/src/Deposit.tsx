import { Dispatch, SetStateAction, useState, useEffect } from "react";
import { TezosToolkit } from "@taquito/taquito";
import { BeaconWallet } from "@taquito/beacon-wallet";
import './App.css';
import {
  NetworkType
} from "@airgap/beacon-sdk";

// reactstrap components

import {
  Button,
  Card,
  CardHeader,
  CardBody,
  CardTitle,
  Col,
  CardFooter,
  CardText,
} from "reactstrap";

type ButtonProps = {
  Tezos: TezosToolkit;
  setWallet: Dispatch<SetStateAction<any>>;
  setUserAddress: Dispatch<SetStateAction<string>>;
  setUserBalance: Dispatch<SetStateAction<number>>
  tokenName: string;
  tokenAddress: string;
  contractAddress: string;
  tokenBalanceUri:string;
  wallet: BeaconWallet;
};

const DepositButton = ({
  Tezos,
  setWallet,
  setUserAddress,
  setUserBalance,
  tokenName,
  tokenAddress,
  contractAddress,
  tokenBalanceUri,
  wallet
}: ButtonProps): JSX.Element => {

  class AddressData {
     address!: string;
  }

  class TokenMetaData {
    name!: string;
    symbol!: string;
    decimals!: string;
  }

  class TokenData {
    id!: number;
    contract!: AddressData;
    tokenId!: string;
    standard!: string;
    totalSupply!: string;
    metadata!: TokenMetaData;
  }

  class ApiTokenBalanceData {
    id!: number;
    account!: AddressData;
    token!: TokenData;
    balance!: string;
    transfersCount!: number;
    firstLevel!: number;
    firstTime!: string;
    lastLevel!: number;
    lastTime!: string;
  }

  class TokenBalance {
   address:string;
   symbol:string;
   decimals:number;
   balance:number;

   constructor(address: string, symbol:string,decimals:number,balance:number) {
      this.address = address;
      this.symbol = symbol;
      this.decimals = decimals;
      this.balance = balance;
   }
  }

  const depositToken = async (): Promise<void> => {
    try {
      
       console.log("Debug:"+tokenBalanceResult);
    } catch (error) {
      console.log(error);
    }
  };


  const [tokenBalanceResult, setTokenBalanceResult] = useState<TokenBalance>();

  const api = async () => {
    const data = await fetch(tokenBalanceUri, {
      method: "GET"
    });
    const jsonData = await data.json();
    const tokenBalances = jsonData as Array<ApiTokenBalanceData>;
    console.log(jsonData);
    const tokenbal : ApiTokenBalanceData = tokenBalances.filter((p:ApiTokenBalanceData)  => p.token.contract.address === tokenAddress)[0];
    const rationalisedBal = parseInt(tokenbal.balance) / (10 ** parseInt(tokenbal.token.metadata.decimals) )
    setTokenBalanceResult(new TokenBalance(tokenbal.token.contract.address,tokenbal.token.metadata.symbol,parseInt(tokenbal.token.metadata.decimals),rationalisedBal));
  };

  useEffect(() => {
    console.log(tokenBalanceUri);
   
    api();
    const interval=setInterval(()=>{
      api()
     },10000)

     return()=>clearInterval(interval)


  }, []);


  return (
       <Col sm="4">
            <Card>
              <CardHeader>
                <h3 className="title">{tokenName}</h3>
              </CardHeader>
              <CardBody>
                <h3 className="title">{tokenBalanceResult?.balance}</h3>
              </CardBody>
              <CardFooter>
                <Button className="btn-danger" color="primary" onClick={depositToken} >
                        Deposit
                </Button>
              </CardFooter>
            </Card>
        </Col>
  );
};

export default DepositButton;
