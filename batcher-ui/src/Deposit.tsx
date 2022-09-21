import { Dispatch, SetStateAction, useState, useEffect } from "react";
import { TezosToolkit } from "@taquito/taquito";
import { BeaconWallet } from "@taquito/beacon-wallet";
import './App.css';
import *  as model from "./Model";
import {
  NetworkType
} from "@airgap/beacon-sdk";

// reactstrap components

import {
  Button,
  ButtonGroup,
  Card,
  CardHeader,
  CardBody,
  CardTitle,
  Col,
  CardFooter,
  CardText,
  Input,
} from "reactstrap";

type ButtonProps = {
  Tezos: TezosToolkit;
  setWallet: Dispatch<SetStateAction<any>>;
  setUserAddress: Dispatch<SetStateAction<string>>;
  setUserBalance: Dispatch<SetStateAction<number>>
  setTokenBalance: Dispatch<SetStateAction<number>>
  setTokenTolerance: Dispatch<SetStateAction<model.selected_tolerance>>
  tokenName: string;
  tokenAddress: string;
  tokenBalance: number;
  tokenTolerance: model.selected_tolerance;
  contractAddress: string;
  tokenBalanceUri:string;
  wallet: BeaconWallet;
};

const DepositButton = ({
  Tezos,
  setWallet,
  setUserAddress,
  setUserBalance,
  setTokenBalance,
  setTokenTolerance,
  tokenName,
  tokenAddress,
  tokenBalance,
  tokenTolerance,
  contractAddress,
  tokenBalanceUri,
  wallet
}: ButtonProps): JSX.Element => {

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



       //Call Deposit endpoint
       const contract  = await Tezos.contract.at(contractAddress);
       const methods = await contract.methods

       console.log("Debug:"+tokenBalanceResult);
       console.log("Debug:"+methods);
    } catch (error) {
      console.log(error);
    }
  };


  const [tokenBalanceResult, setTokenBalanceResult] = useState<TokenBalance>();

  const api = async () => {
    console.log("TOKENURI:" + tokenBalanceUri);
    const data = await fetch(tokenBalanceUri, {
      method: "GET"
    });
    const jsonData = await data.json();
    const tokenBalances = jsonData as Array<model.ApiTokenBalanceData>;
    console.log(jsonData);
    const tokenbal : model.ApiTokenBalanceData = tokenBalances.filter((p:model.ApiTokenBalanceData)  => p.token.contract.address === tokenAddress)[0];
    const rationalisedBal = parseInt(tokenbal.balance) / (10 ** parseInt(tokenbal.token.metadata.decimals) )
    const tkBal = (new TokenBalance(tokenbal.token.contract.address,tokenbal.token.metadata.symbol,parseInt(tokenbal.token.metadata.decimals),rationalisedBal));
    setTokenBalanceResult(tkBal);
    setTokenBalance(tkBal.balance);

  };

  useEffect(() => {
    console.log(tokenBalanceUri);

      (async () => api())();
    const interval=setInterval(()=>{
      (async () => api())();
     },10000)

     return()=>clearInterval(interval)


  }, [tokenBalanceUri]);


  const setTolerance = (selected:number) => {
     if (selected === 0){
       setTokenTolerance(model.selected_tolerance.minus)
     } else if (selected == 1) {
       setTokenTolerance(model.selected_tolerance.exact)
     } else {
       setTokenTolerance(model.selected_tolerance.plus)
     }
  };
  

  return (
       <Col sm="5">
            <Card>
              <CardHeader>
                <h4>Balance : {tokenBalance}  {tokenName}</h4>
              </CardHeader>
              <CardBody>
                 <Input
      id="amount"
      name="amount"
      placeholder="Enter amount to deposit"
      type="text"
    />
                    <ButtonGroup vertical>
        <Button
          color="primary"
          outline
          onClick={() => setTolerance(0)}
          active={tokenTolerance === model.selected_tolerance.minus}
        >
          -10bps
        </Button>
        <Button
          color="primary"
          outline
          onClick={() => setTolerance(1)}
          active={tokenTolerance === model.selected_tolerance.exact}
        >
          Exact Price
        </Button>
        <Button
          color="primary"
          outline
          onClick={() => setTolerance(2)}
          active={tokenTolerance === model.selected_tolerance.plus}
        >
          +10bps
        </Button>
      </ButtonGroup>
                    
              </CardBody>
              <CardFooter>
                <Button block className="btn-danger" color="primary" onClick={depositToken} >
                        Depost {tokenName}
                </Button>
              </CardFooter>
            </Card>
        </Col>
  );
};

export default DepositButton;
