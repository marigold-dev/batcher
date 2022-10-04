import { Dispatch, SetStateAction, useState, useEffect, ChangeEvent } from "react";
import { TezosToolkit } from "@taquito/taquito";
import { BeaconWallet } from "@taquito/beacon-wallet";
import './App.css';
import *  as model from "./Model";
import toast from 'react-hot-toast';

import {
  Button,
  Card,
  CardHeader,
  CardBody,
  Col,
  CardFooter,
  Form,
  Input,
  Row,
} from "reactstrap";

type ButtonProps = {
  Tezos: TezosToolkit;
  setWallet: Dispatch<SetStateAction<any>>;
  setUserAddress: Dispatch<SetStateAction<string>>;
  setTokenBalance: Dispatch<SetStateAction<number>>
  setTokenTolerance: Dispatch<SetStateAction<model.selected_tolerance>>
  token: model.token;
  tokenAddress: string;
  tokenBalance: number;
  tokenTolerance: model.selected_tolerance;
  contractAddress: string;
  tokenBalanceUri:string;
  orderSide: number;
  toToken: model.token;
  wallet: BeaconWallet;
};

const DepositButton = ({
  Tezos,
  setWallet,
  setUserAddress,
  setTokenBalance,
  setTokenTolerance,
  token,
  tokenAddress,
  tokenBalance,
  tokenTolerance,
  contractAddress,
  tokenBalanceUri,
  orderSide,
  toToken,
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

  const [setTokenBalanceResult] = useState<TokenBalance>();
  const [depositAmount, setDepositAmount] = useState<number>(0);
  const [depositButtonColour, setDepositButtonColour] = useState<string>("");

  const transferToken = async (
      tokenAddress:string,
      fromAddress: string,
      toAddress: string,
      token_id: number,
      amount: number
  ) : Promise<void> => {
        const tokenWalletContract = await Tezos.wallet.at(tokenAddress);
        const transfer_params = [
              {
                from_: fromAddress,
                tx : [
                  {
                    to_:toAddress,
                    token_id:token_id,
                    amount: amount
                  }
                ]
              }
           ];
           const token_transfer_op = await tokenWalletContract.methods.transfer(transfer_params).send();
           const confirm = await token_transfer_op.confirmation();
           if(!confirm.completed)
               throw Error("Failed to transfer token");

  };


  const createSwapOrder = async (
      contractAddress:string,
      userAddress : string,
      fromToken: model.token,
      toToken: model.token,
      amount: number,
      side: number,
  ) : Promise<void> => {
        const contractWallet = await Tezos.wallet.at(contractAddress);
        const swap_params =
              {
                trader: userAddress,
                swap : {
                  from:{
                    token: {
                      name: fromToken.name,
                      address: fromToken.address,
                      decimals: fromToken.decimals
                    },
                    amount: amount
                  },
                  to: {
                      name: toToken.name,
                      address: toToken.address,
                      decimals: toToken.decimals
                  }
                },
                created_at : new Date(),
                side: side,
                tolerance: tokenTolerance,
              };
           const swap_creation_op = await contractWallet.methodsObject.deposit(swap_params).send();
           const confirm = await swap_creation_op.confirmation();
           if(!confirm.completed){
               throw Error("Failed to call create swap order");
           }
  };


  const  rationaliseAmount = (amount: number) => {
     let scale =10 ** (token.decimals);
     return amount * scale
  };


  const depositToken = async (): Promise<void> => {
    try {

      if(!wallet) {
          toast.error("Please connect a wallet before depositing");
      } else {
        const depositToastId = 'depositing';
        toast.loading('Attempting to place swap order for ' + token.name, {id: depositToastId} ) ;
        Tezos.setWalletProvider(wallet);
        const userAddress = await wallet.getPKH();
        if(!userAddress){
          await wallet.requestPermissions();
        }

        const scaled_amount = rationaliseAmount(depositAmount);
        toast.loading('Depositing ' + depositAmount + " of " + token.name + " from " + userAddress + " to batcher contract " + contractAddress, {id: depositToastId } ) ;

        try {
            await transferToken(tokenAddress,userAddress,contractAddress,0,scaled_amount);
            toast.success('Deposit of ' + token.name + ' successful', {id: depositToastId});
        } catch (error:any) {
         toast.error("Transfer error : " + error.message, {id: depositToastId });
        }

        const swapToastId = 'swap';
        toast.loading('Creating swap order for ' + depositAmount + " of " + token.name + " from " + userAddress + " to batcher contract " + contractAddress+ ". Side:" + orderSide + " Tolerance:" + tokenTolerance, {id: swapToastId } ) ;

        try {
            await createSwapOrder(contractAddress,userAddress,token,toToken,scaled_amount, orderSide);
            toast.success('Swap order created for ' + token.name + ' successful', {id: swapToastId});
        } catch (error:any) {
         toast.error("Swap error : " + error.message, { id: swapToastId });
        }
      }
    } catch (error) {
      console.log(error);
    }
  };

  const settings = async () => {
     if(orderSide == 0 ){
       setDepositButtonColour("green");
     } else {
       setDepositButtonColour("red");
     }
  };

  const api = async () => {
    if (tokenBalanceUri == "") {
      return null;
    }

    const data = await fetch(tokenBalanceUri, {
      method: "GET"
    });
    const jsonData = await data.json();
    const tokenBalances = jsonData as Array<model.ApiTokenBalanceData>;
    console.log(jsonData);
    const tokenbal : model.ApiTokenBalanceData = tokenBalances.filter((p:model.ApiTokenBalanceData)  => p.token.contract.address === tokenAddress)[0];
    const rationalisedBal = parseInt(tokenbal.balance) / (10 ** parseInt(tokenbal.token.metadata.decimals) )
    const tkBal = (new TokenBalance(tokenbal.token.contract.address,tokenbal.token.metadata.symbol,parseInt(tokenbal.token.metadata.decimals),rationalisedBal));
    setTokenBalance(tkBal.balance);

  };

  useEffect(() => {
    console.log(tokenBalanceUri);

      (async () => settings())();
      (async () => api())();
    const interval=setInterval(()=>{
      (async () => api())();
     },10000)

     return()=>clearInterval(interval)


  }, [tokenBalanceUri]);


  const setDepositValue = (event:ChangeEvent<HTMLInputElement>) => {
    setDepositAmount(event.target.valueAsNumber);
  };

  return (
    <Col sm="5.5">
      <Card>
         <CardHeader>
                <h4>Balance : {tokenBalance}  {token.name}</h4>
         </CardHeader>
         <CardBody>
             <Form>
               <Row className="row-cols-lg-auto g-2 align-items-center">
                <Col className="mr-3">
                  <Input
                    id="amount"
                    name="amount"
                    placeholder="Amount"
                    type="number"
                    onChange={ (e) => setDepositValue(e)}
                  />
                </Col>
                <Col>
                   <Button
                    className="btn-info"
                    size="md"
                  block
                    outline
                    onClick={() => setTokenTolerance(0)}
                    active={tokenTolerance == 0 }
                  >
                    -10bps
                  </Button>
                </Col>
                <Col>
                <Button
                  className="btn-info"
                  size="md"
                  block
                  outline
                  onClick={() => setTokenTolerance(1)}
                  active={tokenTolerance == 1 }
                  >
                  Exact
                </Button>
                </Col>
                <Col>
                <Button
                  className="btn-info"
                  size="md"
                  block
                  outline
                  onClick={() => setTokenTolerance(2)}
                  active={tokenTolerance == 2 }
        >
          +10bps
        </Button>
                </Col>
               </Row>
             </Form>
         </CardBody>
            <CardFooter>
                <Button block className={ orderSide == 0 ? "btn-success" : "btn-danger"} onClick={depositToken} >
                       Swap {token.name} for {toToken.name}
                </Button>
              </CardFooter>
      </Card>
    </Col>


  );
};

export default DepositButton;
