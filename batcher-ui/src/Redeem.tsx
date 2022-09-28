import { Dispatch, SetStateAction, useState, useEffect, ChangeEvent } from "react";
import { TezosToolkit } from "@taquito/taquito";
import { BeaconWallet } from "@taquito/beacon-wallet";
import { JSONPath } from "jsonpath-plus";
import { Contract, ContractsService, MichelineFormat, AccountsService, HeadService } from '@dipdup/tzkt-api';
import './App.css';
import *  as model from "./Model";
import toast, { Toaster } from 'react-hot-toast';
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
  FormGroup,
  Form,
  Input,
  Label,
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
    try{

      let treasuries = previousBatches.map(th => th.treasury);
      let base_holdings = 0;
      let quote_holdings = 0;
      for(var i = 0;i<treasuries.length;i++) { 
        try{

           let bm_uri = bigMapsById + treasuries[i] + "/keys/" + userAddress;
           const data = await fetch(bm_uri, {
              method: "GET"
            });
           const jsonData = await data.json();
           const amounts = JSONPath({ path: "$.value.*.token_amount", json: jsonData });
           const tokenAmounts = amounts as Array<model.token_amount>;
           try{
              base_holdings = tokenAmounts.reduce((previousAmount, token_amount) => {
                if (token_amount.token.name == token.name){
                  previousAmount += rationaliseAmount(token_amount.amount, token.decimals);
                }
                return previousAmount;
              }, 0)
            }     
            catch (error){  
              console.log("Error getting base holdings:" + error);
            }
            
            try{
              quote_holdings = tokenAmounts.reduce((previousAmount, token_amount) => {
                if (token_amount.token.name == toToken.name){
                  previousAmount += rationaliseAmount(token_amount.amount, toToken.decimals);
                }
                return previousAmount;
              }, 0)
            } catch(error) {

              console.log("Error getting quote holdings:" + error);

            }

            setBaseTokenRedeemableHoldings(base_holdings);
            setQuoteTokenRedeemableHoldings(quote_holdings);

        } catch 
        {

        }
   


      }
  }
  catch (error){
     console.log("Unable to get holdings" + error);
     return 0;
  }
};

  useEffect(() => {

      (async () => get_redeemable_holdings())();
    const interval=setInterval(()=>{
      (async () => get_redeemable_holdings())();
     },20000)

     return()=>clearInterval(interval)


  }, [userAddress]);


  const redeemHoldings = async () : Promise<void> => {
         const contractWallet = await Tezos.wallet.at(contractAddress);
         const redeem_op = await contractWallet.methodsObject.redeem().send();
         const confirm = await redeem_op.confirmation();
         if(!confirm.completed){
             throw Error("Failed to redeem holdings");
         }
};


  return (
    <Col>
      <Card>
         <CardHeader>
                <h4 className="title">Redeemable Holdings</h4>
         </CardHeader>
         <CardBody>
                    <Table size="sm">
                    <Row>
                        <Col className="col-4"><h6 className="title d-inline">{token.name} holdings</h6></Col>
                        <Col className="px-sm-0">{ baseTokenRedeemableHoldings } {token.name}</Col>
                      </Row>
                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">{toToken.name} holdings</h6></Col>
                        <Col className="px-sm-0">{ quoteTokenRedeemableHoldings} {toToken.name}</Col>
                      </Row>
                      </Table>
         </CardBody>
            <CardFooter>
                <Button block className="btn-success" onClick={redeemHoldings} >
                     Redeem Holdings
                </Button>
              </CardFooter>
      </Card>
    </Col>


  );
};

export default RedeemButton;
