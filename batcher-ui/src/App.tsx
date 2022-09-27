import React, { useEffect, useState } from 'react';
import logo from './logo.svg';
import marigoldlogo from './marigoldlogo.png';
import ConnectButton from './ConnectWallet';
import { TezosToolkit, WalletContract, MichelsonMap } from '@taquito/taquito';
import { Tzip12Module } from '@taquito/tzip12';
import { Tzip16Module } from '@taquito/tzip16';
import DisconnectButton from './DisconnectWallet';
import DepositButton from './Deposit';
import RedeemButton from './Redeem';
import { Contract, ContractsService, MichelineFormat, AccountsService, HeadService } from '@dipdup/tzkt-api';
import { parseISO, add, differenceInMinutes } from 'date-fns'
import './App.css';
import *  as model from "./Model";
import { Helmet } from 'react-helmet';
import toast, { Toaster } from 'react-hot-toast';
// reactstrap components
import {
  Button,
  ButtonGroup,
  Card,
  CardHeader,
  CardBody,
  CardTitle,
  DropdownToggle,
  DropdownMenu,
  DropdownItem,
  UncontrolledDropdown,
  Label,
  FormGroup,
  Input,
  Table,
  Row,
  Col,
  CardFooter,
  CardText,
  Form,

  UncontrolledTooltip
} from "reactstrap";
import { time } from 'console';


function App() {

  const [Tezos, setTezos] = useState<TezosToolkit>(new TezosToolkit("https://jakartanet.tezos.marigold.dev"));

  const baseTokenName = "tzBTC";
  const baseTokenAddress = "KT1XBUuCDb7ruPcLCpHz4vrh9jL9ogRFYTpr";
  const baseTokenDecimals = 8;
  const quoteTokenName ="USDT";
  const quoteTokenAddress ="KT1AqXVEApbizK6ko4RqtCVdgw8CQd1xaLsF";
  const quoteTokenDecimals = 6;
  const [wallet, setWallet] = useState<any>(null);
  const [userAddress, setUserAddress] = useState<string>("No Wallet Connected");
  const [userBalance, setUserBalance] = useState<number>(0);
  const [refreshRate, setRefreshRate] = useState<number>(10000);
  const mainPanelRef = React.useRef(null);
  const sidebarRef = React.useRef(null);
  const [exchangeRate, setExchangeRate] = useState<number | undefined>();
  const [stringStorage, setStringStorage] = useState<string>("");
  const [remaining, setRemaining] = useState<string>("No open batch");
  const [orderBook, setOrderBook] = useState<model.order_book | undefined>(undefined);
  const [previousBatches, setPreviousBatches] = useState<Array<model.batch>>([]);
  const [numberOfBids, setNumberOrBids] = useState<number>(0);
  const [numberOfAsks, setNumberOrAsks] = useState<number>(0);

  const [storage, setStorage] = useState<model.ContractStorage | undefined>();
  const [contractAddress, setContractAddress] = useState<string>("KT1T7q2HobgiSWbmbc3thX1798PHFMBaLyzx");
  const baseToken :  model.token = {name : baseTokenName, address : baseTokenAddress, decimals : baseTokenDecimals};
  const [baseTokenBalance, setBaseTokenBalance] = useState<number>(0);
  const [baseTokenTolerance, setBaseTokenTolerance] = useState<number>(1);
  const quoteToken :  model.token = {name : quoteTokenName, address : quoteTokenAddress, decimals : quoteTokenDecimals};
  const [quoteTokenBalance, setQuoteTokenBalance] = useState<number>(0);
  const [quoteTokenTolerance, setQuoteTokenTolerance] = useState<number>(1);
  const [tokenPair, setTokenPair] = useState<string>(""+baseTokenName+"/"+quoteTokenName);
  const [invertedTokenPair, setInvertedTokenPair] = useState<string>(""+quoteTokenName+"/"+baseTokenName);
  const [lastBlockHeight, setLastBlockHeight] = useState<number>(0);
  const [tokenBalanceUri, setTokenBalanceUri] = useState<string>("");
  const [bigMapByIdUri, setBigMapByIdUri] = useState<string>("");
   //tzkt
   //
  const chain_api_url = "https://api.jakartanet.tzkt.io"
  const contractsService = new ContractsService( {baseUrl: chain_api_url , version : "", withCredentials : false});
  const accountsService = new AccountsService( {baseUrl: chain_api_url , version : "", withCredentials : false});
  const headService = new HeadService( {baseUrl: chain_api_url , version : "", withCredentials : false});

  const rationalise_rate  = ( rate : number , base_decimals :  number, quote_decimals : number) => {
     let scale =10 ** (base_decimals - quote_decimals);
     return rate * scale
  }



  const get_time_left_in_batch = ( status:string) => {
    console.log(status);
    let statusObject = JSON.parse(status);
    console.log(statusObject);
    if(status.search("closed") > -1){
        let close = parseISO(statusObject.closed.closing_time);
        return "Batch was closed at " + close;
    } else if (status.search("open") > -1){
      let now = new Date();
      let open = parseISO(statusObject.open);
      let batch_close = add(open,{ minutes: 10})
      let diff = differenceInMinutes(batch_close, now);
      let rem = "";
      if (diff <= 0) {
         rem = "0"
        } else {
          rem = "" + diff
        };
       return ""+rem+" minutes" ;
    } else if (status.search("cleared")) {
        let cleared = parseISO(statusObject.cleared.at);
        return "Batch was cleared at " + cleared;
    }
     else {
        return "No open batch";
    }


  }

  const  rationaliseAmount = (amount: number, decimals: number) => {
     let scale =10 ** (-decimals);
     return amount * scale
  };

  const get_token_by_side = (decimals: number, tolerance : string, order_sides : Array<model.swap_order>) => {
    try{
    let token_name = order_sides[0].swap.from.token.name;

    let amount = order_sides.reduce((previousAmount, order) => {
      if (Object.keys(order.tolerance)[0] === tolerance) {
        previousAmount += Number(order.swap.from.amount);
      }

      return previousAmount;
    }, 0);
    let corrected_amount = rationaliseAmount(amount, decimals);
    return token_name.concat(" : ", Number(corrected_amount).toString());
  }
  catch (error){
    return "No orders";
  }
  }



  const update_from_storage = async () => {


    console.log("Updating storage");
    console.log(contractAddress);
    //const tcontract =  await Tezos.contract.at(contractAddress);
    const storage = await contractsService.getStorage( { address : contractAddress, level: 0, path: null } );
    const rates_map_keys = await contractsService.getBigMapByNameKeys( { address : contractAddress, name: "rates_current", micheline: MichelineFormat.JSON } )
    console.log(rates_map_keys);
    const exchange_rate : model.exchange_rate = rates_map_keys.filter(r => r.key == invertedTokenPair)[0].value;
    const scaled_rate = rationalise_rate(exchange_rate.rate.val, exchange_rate.swap.to.decimals, exchange_rate.swap.from.token.decimals);
    setExchangeRate(scaled_rate);
    console.log("Updated Exchange Rate");


    try{
       const current_batch_status= await storage.batches.current.status;
       let time_remaining = get_time_left_in_batch(JSON.stringify(current_batch_status));
       setRemaining(time_remaining);
    } catch (e) {
       console.error(e);
       setRemaining("No open batch");
    }

    console.log("Updated Time Remaining");

    try{
      const order_book : model.order_book = await storage.batches.current.orderbook;
      setOrderBook(order_book);
      setNumberOrBids(order_book.bids.length);
      setNumberOrAsks(order_book.asks.length);
    } catch {
      let empty_order = new model.order_book();
      setOrderBook(empty_order);
      setNumberOrBids(0);
      setNumberOrAsks(0);
    }

    console.log("Updated Order Book");


    try{

      setPreviousBatches(storage.batches.previous);
    }
    catch(error) {
       console.log(error)
    }


  };


  const updateUriSettings = async (): Promise<void> => {
   try{
     console.log("Updating Token Balance URI");
    setTokenBalanceUri(""+ chain_api_url + "/v1/tokens/balances?account=" + userAddress);
     console.log(tokenBalanceUri);
    setBigMapByIdUri(""+ chain_api_url + "/v1/bigmaps/");
   } catch (error)
   {
      console.log(error);
   }

  }

  useEffect(() => {
      (async () => updateUriSettings())();
  }, [userAddress])

  const updateValues = async (): Promise<void> => {
    try {
      await update_from_storage();
    } catch (error) {
      console.log(error);
    }
  };



  useEffect(() => {

      (async () => updateValues())();
    const interval=setInterval(()=>{
      (async () => updateValues())();
     },refreshRate)

     return()=>clearInterval(interval)


  }, [tokenBalanceUri])

  return (


          <div className="wrapper">
            <div className="main-panel" ref={mainPanelRef} >

            <Helmet>
                <meta charSet="utf-8" />
                <title>Batcher</title>
                <link rel="canonical" href="http://batcher.marigold.dev" />
            </Helmet>
      <div className="content">
        <Row  className="pr-5 mr-3">
          <Col>
            <Card >
              <CardHeader>
                  <Col className="text-left float-left" sm="4">
                    <CardTitle tag="h1"><img src={logo} height="150" alt="logo"/></CardTitle>
                  </Col>
                  <Col className="text-right float-right" sm="4">
                    <CardTitle tag="h1"><img src={marigoldlogo} height="150" alt="logo"/></CardTitle>
                    </Col>
                </CardHeader>
                <CardBody>
                </CardBody>
              </Card>
            </Col>
          </Row>

        <Row>
          <Col sm="8">
              <Card sm="5.5">
              <CardHeader>
                <h4 className="title d-inline">POOL: tzBTC / USDT</h4>
              </CardHeader>
              <CardBody>
                <h4 className="title d-inline">Current Batch</h4>
                <Table size="md">
                  <Row className="sm-5 sp-5">
                  <Col>
                  <Row>
                    <Col className="col-4"><h6 className="title d-inline">Oracle Price</h6></Col>
                  </Row>
                 <Row>
                    <Col className="sm-1">{ exchangeRate } </Col>
                 </Row>
                  </Col>
                  <Col>
                  <Row>
                    <Col className="col-4"><h6 className="title d-inline">Time Remaining</h6></Col>
                  </Row>
                 <Row>
                    <Col className="sm-0">{ remaining }</Col>
                 </Row>
                  </Col>
                  <Col>
                  <Row>
                    <Col className="col-4"><h6 className="title d-inline">Bids Orders</h6></Col>
                  </Row>
                 <Row>
                    <Col className="sm-0">{ numberOfBids }</Col>
                 </Row>
                  </Col>
                  <Col>
                  <Row>
                    <Col className="col-4"><h6 className="title d-inline">Ask Orders</h6></Col>
                  </Row>
                 <Row>
                    <Col className="sm-0">{ numberOfAsks }</Col>
                 </Row>
                  </Col>
                  </Row>
                </Table>
              </CardBody>
              <CardFooter>

              </CardFooter>
            </Card>
            <DepositButton
                Tezos={Tezos}
                setWallet={setWallet}
                setUserAddress={setUserAddress}
                setUserBalance={setUserBalance}
                setTokenBalance={setBaseTokenBalance}
                setTokenTolerance={setBaseTokenTolerance}
                token={baseToken}
                tokenAddress={baseTokenAddress}
                tokenBalance={baseTokenBalance}
                tokenTolerance={baseTokenTolerance}
                contractAddress={contractAddress}
                tokenBalanceUri={tokenBalanceUri}
                orderSide={0}
                toToken={quoteToken}
                wallet={wallet}
            />
             <DepositButton
                Tezos={Tezos}
                setWallet={setWallet}
                setUserAddress={setUserAddress}
                setUserBalance={setUserBalance}
                setTokenBalance={setQuoteTokenBalance}
                setTokenTolerance={setQuoteTokenTolerance}
                token={quoteToken}
                tokenAddress={quoteTokenAddress}
                tokenBalance={quoteTokenBalance}
                tokenTolerance={quoteTokenTolerance}
                contractAddress={contractAddress}
                tokenBalanceUri={tokenBalanceUri}
                orderSide={1}
                toToken={baseToken}
                wallet={wallet}
            />
            <Row>
            </Row>
          </Col>
          <Col className="position-relative" sm="3">
            <Row>
            <Card>
            <CardHeader>
                <h4 className="title d-inline">Wallet</h4>
              </CardHeader>
              <CardBody>
              <Table size="md">
              <Row className="sm-5 sp-5">
                  <Col>
                    <Row>
                    <Col className="col-4"><h6 className="title d-inline">User Address</h6></Col>
                    </Row>
                   <Row>
                      <Col className="sm-1">{ userAddress } </Col>
                    </Row>
                    </Col>
               </Row>
              <Row className="mt-4 sp-5">
                  <Col>
                <ConnectButton
                  Tezos={Tezos}
                  setWallet={setWallet}
                  setUserAddress={setUserAddress}
                  setUserBalance={setUserBalance}
                  userAddress={userAddress}
                  wallet={wallet}
                />
                  </Col>
                  <Col>
               <DisconnectButton
               wallet={wallet}
               setUserAddress={setUserAddress}
               setUserBalance={setUserBalance}
               userAddress={userAddress}
               setWallet={setWallet}
               />
                  </Col>
               </Row>
              </Table>
              </CardBody>
            </Card>
            <Card>
              <CardHeader>
                <h4 className="title">Order Book</h4>
              </CardHeader>
              <CardBody>
                 <Row>
                   <Col>
                    <h4 className="title d-inline">Bids</h4>
                    <Table size="sm">

                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">-10bps</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side(baseToken.decimals, "mINUS", orderBook?.bids!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">EXACT</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side(baseToken.decimals,"eXACT", orderBook?.bids!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">+10bps</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side(baseToken.decimals,"pLUS", orderBook?.bids!)}</Col>
                      </Row>
                   </Table>

                   </Col>
                   <Col>
                    <h4 className="title d-inline">Asks</h4>
                    <Table size="sm">
                    <Row>
                        <Col className="col-4"><h6 className="title d-inline">-10bps</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side(quoteToken.decimals,"mINUS", orderBook?.asks!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">EXACT</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side(quoteToken.decimals,"eXACT", orderBook?.asks!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">+10bps</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side(quoteToken.decimals,"pLUS", orderBook?.asks!)}</Col>
                      </Row>

                   </Table>

                   </Col>
                 </Row>
              </CardBody>
              <CardFooter>
              </CardFooter>
            </Card>
            </Row>
            <Row>


             <RedeemButton
                Tezos={Tezos}
                token={quoteToken}
                previousBatches={previousBatches}
                userAddress={userAddress}
                toToken={baseToken}
                wallet={wallet}
                contractAddress={contractAddress}
                bigMapsById={bigMapByIdUri}
            />

            </Row>
          </Col>
        </Row>
 </div>      </div>
            </div>


  );
}

export default App;
