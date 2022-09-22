import React, { useEffect, useState } from 'react';
import logo from './logo.svg';
import marigoldlogo from './marigoldlogo.png';
import ConnectButton from './ConnectWallet';
import { TezosToolkit, WalletContract, MichelsonMap } from '@taquito/taquito';
import { Tzip12Module } from '@taquito/tzip12';
import { Tzip16Module } from '@taquito/tzip16';
import DisconnectButton from './DisconnectWallet';
import DepositButton from './Deposit';
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
  const [numberOfBids, setNumberOrBids] = useState<number>(0);
  const [numberOfAsks, setNumberOrAsks] = useState<number>(0);
  
  const [storage, setStorage] = useState<model.ContractStorage | undefined>();
  const [contractAddress, setContractAddress] = useState<string>("KT1CQw5Yo7cecCu496noAZDngeCUxhtHv5jC");
  const [baseTokenName, setBaseTokenName] = useState<string>("tzBTC");
  const [baseTokenAddress, setBaseTokenAddress] = useState<string>("KT1XBUuCDb7ruPcLCpHz4vrh9jL9ogRFYTpr");
  const [baseTokenBalance, setBaseTokenBalance] = useState<number>(0);
  const [baseTokenTolerance, setBaseTokenTolerance] = useState<model.selected_tolerance>(model.selected_tolerance.exact);
  const [quoteTokenName, setQuoteTokenName] = useState<string>("USDT");
  const [quoteTokenAddress, setQuoteTokenAddress] = useState<string>("KT1AqXVEApbizK6ko4RqtCVdgw8CQd1xaLsF");
  const [quoteTokenBalance, setQuoteTokenBalance] = useState<number>(0);
  const [quoteTokenTolerance, setQuoteTokenTolerance] = useState<model.selected_tolerance>(model.selected_tolerance.exact);
  const [tokenPair, setTokenPair] = useState<string>(""+baseTokenName+"/"+quoteTokenName);
  const [invertedTokenPair, setInvertedTokenPair] = useState<string>(""+quoteTokenName+"/"+baseTokenName);
  const [lastBlockHeight, setLastBlockHeight] = useState<number>(0);
  const [tokenBalanceUri, setTokenBalanceUri] = useState<string>("");
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


  const extract_contract_schema = async () => {

Tezos.contract
  .at(contractAddress)
  .then((c) => {
    let methods = c.parameterSchema.ExtractSignatures();
    setStringStorage(JSON.stringify(methods, null, 2));
  })
  .catch((error) => console.log(`Error: ${error}`));

  };

  const get_time_left_in_batch = (staus:model.batch_status) => {
    let batch_open = staus.open;
    let now = new Date();
    let open = parseISO(batch_open);
    let batch_close = add(open,{ minutes: 10})
    let diff = differenceInMinutes(batch_close, now);
     return ""+diff+" minutes" ;
  }


  const get_token_by_side = (tolerance : string, order_sides : Array<model.swap_order>) => {
    try{
    let token_name = order_sides[0].swap.from.token.name;

    let amount = order_sides.reduce((previousAmount, order) => {
      if (Object.keys(order.tolerance)[0] === tolerance) {
        previousAmount += Number(order.swap.from.amount);
      } 
       
      return previousAmount;
    }, 0);

    return token_name.concat(" : ", Number(amount).toString());
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
    const rates_map = await contractsService.getBigMapByName( { address : contractAddress, name: "rates_current", micheline: MichelineFormat.JSON } );
    const rates_map_keys = await contractsService.getBigMapByNameKeys( { address : contractAddress, name: "rates_current", micheline: MichelineFormat.JSON } )
    console.log(rates_map_keys);
    const exchange_rate : model.exchange_rate = rates_map_keys.filter(r => r.key == invertedTokenPair)[0].value;
    const scaled_rate = rationalise_rate(exchange_rate.rate.val, exchange_rate.swap.to.decimals, exchange_rate.swap.from.token.decimals);
    setExchangeRate(scaled_rate);

    const current_batch_status:model.batch_status = await storage.batches.current.status;
    const time_remaining = get_time_left_in_batch(current_batch_status);
    setRemaining(time_remaining);

    const order_book : model.order_book = await storage.batches.current.orderbook;
    setOrderBook(order_book);
    setNumberOrBids(order_book.bids.length);
    setNumberOrAsks(order_book.asks.length);

    const last_head = await headService.get();

    setLastBlockHeight(last_head.quoteLevel || 0);


    const balances = await accountsService.getBalanceAtLevel({ address : userAddress, level: lastBlockHeight});


    const _updateStrings = await extract_contract_schema();

  };


  const updateTokenUri = async (): Promise<void> => {
   try{
     console.log("Updating Token Balance URI");
    setTokenBalanceUri(""+ chain_api_url + "/v1/tokens/balances?account=" + userAddress);
     console.log(tokenBalanceUri);
   } catch (error)
   {
      console.log(error);
   }

  }

  useEffect(() => {
      (async () => updateTokenUri())();
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
        <Row>
          <Col xs="11">
            <Card className="card-chart">
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
            <Row>
              <Card>
              <CardHeader>
                <h3 className="title">POOL: tzBTC / USDT</h3>
              </CardHeader>
              <CardBody>
                 <Row>
                   <Col sm="2">
                      <h4 className="title d-inline">Oracle Price</h4>
                      <p className="description bold">{ exchangeRate } USDT / tzBTC </p>
                     </Col>
                   <Col sm="2">
                      <h4 className="title d-inline">Time Remaining in Current Batch</h4>
                      <p className="description bold"> { remaining} </p>
                     </Col>
                   <Col sm="2">
                      <h4 className="title d-inline">Buy Orders in Current Batch</h4>
                      <p className="description bold">{ numberOfBids}</p>
                     </Col>
                   <Col sm="2">
                      <h4 className="title d-inline">Sell orders in Current Batch</h4>
                      <p className="description bold"> {numberOfAsks}</p>
                     </Col>
                 </Row>
                 <Row>
                   <Col sm="6">
                      <h4 className="title d-inline">Storage</h4>
                      <p className="description bold">{ stringStorage }</p>
                     </Col>
                 </Row>
              </CardBody>
              <CardFooter>

              </CardFooter>
            </Card>
            </Row>
            <Row>
            <DepositButton
                Tezos={Tezos}
                setWallet={setWallet}
                setUserAddress={setUserAddress}
                setUserBalance={setUserBalance}
                setTokenBalance={setBaseTokenBalance}
                setTokenTolerance={setBaseTokenTolerance}
                tokenName={baseTokenName}
                tokenAddress={baseTokenAddress}
                tokenBalance={baseTokenBalance}
                tokenTolerance={baseTokenTolerance}
                contractAddress={contractAddress}
                tokenBalanceUri={tokenBalanceUri}
                wallet={wallet}
            />
             <DepositButton
                Tezos={Tezos}
                setWallet={setWallet}
                setUserAddress={setUserAddress}
                setUserBalance={setUserBalance}
                setTokenBalance={setQuoteTokenBalance}
                setTokenTolerance={setQuoteTokenTolerance}
                tokenName={quoteTokenName}
                tokenAddress={quoteTokenAddress}
                tokenBalance={quoteTokenBalance}
                tokenTolerance={quoteTokenTolerance}
                contractAddress={contractAddress}
                tokenBalanceUri={tokenBalanceUri}
                wallet={wallet}
            />
            </Row>
          </Col>
          <Col sm="3">
            <Row>
            <Card>
              <CardHeader>
                 <h3 className="title">{userAddress}</h3>
              </CardHeader>
              <CardBody>
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
              </CardBody>
              <CardFooter>
                <div className="button-container">
                </div>
              </CardFooter>
            </Card>
            </Row>
            <Row>
            <Card>
              <CardHeader>
                <h3 className="title">Order Book</h3>
              </CardHeader>
              <CardBody>
                 <Row>
                   <Col>
                    <h4 className="title d-inline">Bids</h4>
                    <Table size="sm">

                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">MINUS 10bps</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("mINUS", orderBook?.bids!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">EXACT</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("eXACT", orderBook?.bids!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">PLUS 10bps</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("pLUS", orderBook?.bids!)}</Col>
                      </Row>
                   </Table>
                      
                   </Col>
                   <Col>
                    <h4 className="title d-inline">Asks</h4>
                    <Table size="sm">
                    <Row>
                        <Col className="col-4"><h6 className="title d-inline">MINUS 10bps</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("mINUS", orderBook?.asks!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">EXACT</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("eXACT", orderBook?.asks!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-4"><h6 className="title d-inline">PLUS 10bps</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("pLUS", orderBook?.asks!)}</Col>
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
            </Row>
          </Col>
        </Row>
 </div>      </div>
            </div>


  );
}

export default App;
