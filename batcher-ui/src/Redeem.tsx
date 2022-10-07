import {  useState, useEffect } from "react";
import { TezosToolkit } from "@taquito/taquito";
import { BeaconWallet } from "@taquito/beacon-wallet";
import { JSONPath } from "jsonpath-plus";
import './App.css';
import *  as model from "./Model";
import toast from 'react-hot-toast';

// reactstrap components

import {
  Button,
  Card,
  CardHeader,
  CardBody,
  Col,
  CardFooter,
  Row,
  Table,
} from "reactstrap";

type ButtonProps = {
  Tezos: TezosToolkit;
  token: model.token;
  previousBatches: Array<model.batch>;
  userAddress: string;
  toToken: model.token;
  wallet: BeaconWallet;
  contractAddress: string,
  bigMapsById: string
};

const RedeemButton = ({
  Tezos,
  token,
  previousBatches,
  userAddress,
  toToken,
  wallet,
  contractAddress,
  bigMapsById
}: ButtonProps): JSX.Element => {


  const [baseTokenRedeemableHoldings, setBaseTokenRedeemableHoldings] = useState<number>(0);
  const [quoteTokenRedeemableHoldings, setQuoteTokenRedeemableHoldings] = useState<number>(0);

  const  rationaliseAmount = (amount: number, decimals:number) => {
    let scale =10 ** -(decimals);
    return amount * scale
 };


  const get_redeemable_holdings = async () => {
    let treasuries = previousBatches.map(th => th.treasury);
    let base_holdings = 0;
    let quote_holdings = 0;

    for (var i = 0; i < treasuries.length; i++) {
      let bm_uri = bigMapsById + treasuries.at(i) + "/keys/" + userAddress;
      const data = await fetch(bm_uri, {
        method: "GET"
      });
      const jsonData = await data.json();
      const amounts = JSONPath({ path: "$.value.*.token_amount", json: jsonData });
      const tokenAmounts = amounts as Array<model.token_amount>;
      base_holdings = tokenAmounts.reduce((previousAmount, token_amount) => {
        if (token_amount.token.name == token.name){
          previousAmount += rationaliseAmount(token_amount.amount, token.decimals);
        }
        return previousAmount;
      }, 0);

      quote_holdings = tokenAmounts.reduce((previousAmount, token_amount) => {
        if (token_amount.token.name == toToken.name){
          previousAmount += rationaliseAmount(token_amount.amount, toToken.decimals);
        }
        return previousAmount;
      }, 0);

      setBaseTokenRedeemableHoldings(base_holdings);
      setQuoteTokenRedeemableHoldings(quote_holdings);
    }

    return null;
  };

  useEffect(() => {
    console.log(userAddress);
    (async () => get_redeemable_holdings())();
    const interval=setInterval(()=>{
      (async () => get_redeemable_holdings())();
     },20000)

     return()=>clearInterval(interval)


  }, [userAddress, previousBatches]);


  const redeemHoldings = async () : Promise<void> => {
        const redeemToastId = 'redeem';
        toast.loading('Attempting to redeem holdings....', {id: redeemToastId } ) ; 
        const contractWallet = await Tezos.wallet.at(contractAddress);
        const redeem_op = await contractWallet.methodsObject.redeem().send();
        const confirm = await redeem_op.confirmation();
         if(!confirm.completed){
            toast.error('Failed to redeem holdings', {id: redeemToastId } ) ; 
             throw Error("Failed to redeem holdings");
         } else {
            toast.success('Successfully redeemed holdings', {id: redeemToastId } ) ; 
         }
};


  return (
      <Card>
         <CardHeader>
                <h5 className="title">Redeemable Holdings</h5>
         </CardHeader>
         <CardBody style={{marginBottom:"0.6em"}}>
                    <Row>
                        <Col className="col-4"><h6 className="title d-inline">{token.name} holdings</h6></Col>
                        <Col className="px-sm-0">{ baseTokenRedeemableHoldings } {token.name}</Col>
                      </Row>
                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">{toToken.name} holdings</h6></Col>
                        <Col className="px-sm-0">{ quoteTokenRedeemableHoldings} {toToken.name}</Col>
                      </Row>
         </CardBody>
            <CardFooter style={{paddingBottom:"1.4em"}}>
                <Button block className="btn-success" onClick={redeemHoldings} >
                     Redeem Holdings
                </Button>
              </CardFooter>
      </Card>


  );
};

export default RedeemButton;
