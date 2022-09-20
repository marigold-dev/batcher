import React, { useEffect } from 'react';
import logo from './logo.svg';
import marigoldlogo from './marigoldlogo.png';
import { useState, useEffect } from 'react';
import ConnectButton from './ConnectWallet';
import { TezosToolkit, WalletContract, MichelsonMap } from '@taquito/taquito';
import { Tzip12Module } from '@taquito/tzip12';
import { Tzip16Module } from '@taquito/tzip16';
import DisconnectButton from './DisconnectWallet';
import DepositButton from './Deposit';
import { Contract, ContractsService, MichelineFormat, AccountsService, HeadService } from '@dipdup/tzkt-api';
import { parseISO, add, differenceInMinutes } from 'date-fns'
import './App.css';
import { Helmet } from 'react-helmet';
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
  class token {
   name!: string;
   address!: string;
   decimals!:number;
  }

  class token_amount {
    token!: token;
    amount!: number;
  }

  class swap {
     from!: token_amount;
     to!: token;
  }

  class float_t {
    pow!: number;
    val!: number;
  }

  class exchange_rate {
     swap!: swap;
     rate!: float_t;
     when!: string;
  }

 interface Tolerance {
  eXACT?: EXact
  mINUS?: MInus
  pLUS?: PLus
}

 interface EXact {}
 interface MInus {}
 interface PLus {}


  class swap_order {
    trader!: string;
    swap!: swap;
    created_at!: string;
    side!: string;
    tolerance!: Tolerance;
  }

  class order_book {
    bids!: Array<swap_order>;
    asks!: Array<swap_order>;
  }

  class token_holding {
    holder!:string;
    token_amount!: token_amount;

  }

  class batch_status {
     open!: string;
  }

  class batch {
      status!: batch_status;
      treasury!: MichelsonMap<string, Map<string, token_holding>>;
      orderbook!: order_book;
      pair!: [token, token];
  }

  class batch_set {
     current!: batch;
     previous!: Array<batch>

  }
  class ContractStorage {
    valid_tokens!: Array<token>;
    valid_swaps!: Map<string,swap>;
    rates_current!: MichelsonMap<string,exchange_rate>;
    batches!: batch_set;
  }

  const [wallet, setWallet] = useState<any>(null);
  const [userAddress, setUserAddress] = useState<string>("No Wallet Connected");
  const [userBalance, setUserBalance] = useState<number>(0);
  const mainPanelRef = React.useRef(null);
  const sidebarRef = React.useRef(null);
  const [exchangeRate, setExchangeRate] = useState<number | undefined>();
  const [stringStorage, setStringStorage] = useState<string>("");
  const [remaining, setRemaining] = useState<string>("");
  const [orderBook, setOrderBook] = useState<order_book | undefined>(undefined);
  const [numberOfBids, setNumberOrBids] = useState<number>(0);
  const [numberOfAsks, setNumberOrAsks] = useState<number>(0);
  const [storage, setStorage] = useState<ContractStorage | undefined>();
  const [contractAddress, setContractAddress] = useState<string>("KT1PyZqjjEJrorcxUg7mNnHeE2ZwNVApCniz");
  const [baseTokenName, setBaseTokenName] = useState<string>("tzBTC");
  const [baseTokenAddress, setBaseTokenAddress] = useState<string>("KT1XBUuCDb7ruPcLCpHz4vrh9jL9ogRFYTpr");
  const [quoteTokenName, setQuoteTokenName] = useState<string>("USDT");
  const [quoteTokenAddress, setQuoteTokenAddress] = useState<string>("KT1AqXVEApbizK6ko4RqtCVdgw8CQd1xaLsF");
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

  const get_time_left_in_batch = (staus:batch_status) => {
    let batch_open = staus.open;
    let now = new Date();
    let open = parseISO(batch_open);
    let batch_close = add(open,{ minutes: 10})
    let diff = differenceInMinutes(batch_close, now);
     return ""+diff+" minutes" ;
  }


  const get_token_by_side = (tolerance : string, order_sides : Array<swap_order>) => {
    let token_name = order_sides[0].swap.from.token.name;

    let amount = order_sides.reduce((previousAmount, order) => {
      if (Object.keys(order.tolerance)[0] === tolerance) {
        previousAmount += Number(order.swap.from.amount);
      } 
       
      return previousAmount;
    }, 0);

    return token_name.concat(" : ", Number(amount).toString());
  }

  const update_from_storage = async () => {

  

    console.log(contractAddress);
    //const tcontract =  await Tezos.contract.at(contractAddress);
    const storage = await contractsService.getStorage( { address : contractAddress, level: 0, path: null } );
    const rates_map = await contractsService.getBigMapByName( { address : contractAddress, name: "rates_current", micheline: MichelineFormat.JSON } );
    const rates_map_keys = await contractsService.getBigMapByNameKeys( { address : contractAddress, name: "rates_current", micheline: MichelineFormat.JSON } )
    console.log(rates_map_keys);
    const exchange_rate : exchange_rate = rates_map_keys.filter(r => r.key == invertedTokenPair)[0].value;
    const scaled_rate = rationalise_rate(exchange_rate.rate.val, exchange_rate.swap.to.decimals, exchange_rate.swap.from.token.decimals);
    setExchangeRate(scaled_rate);

    const current_batch_status:batch_status = await storage.batches.current.status;
    const time_remaining = get_time_left_in_batch(current_batch_status);
    setRemaining(time_remaining);

    const order_book : order_book = await storage.batches.current.orderbook;
    setOrderBook(order_book);
    setNumberOrBids(order_book.bids.length);
    setNumberOrAsks(order_book.asks.length);

    const last_head = await headService.get();

    setLastBlockHeight(last_head.quoteLevel || 0);


    const balances = await accountsService.getBalanceAtLevel({ address : userAddress, level: lastBlockHeight});

    setTokenBalanceUri(""+ chain_api_url + "/v1/tokens/balances?account=" + userAddress);


    setStringStorage(JSON.stringify(balances));
    setStorage(storage);

  };

  const updateValues = async (): Promise<void> => {
    try {
      await update_from_storage();
      console.log(exchangeRate);
    } catch (error) {
      console.log(error);
    }
  };

  useEffect(() => {
      (async () => updateValues())();
  }, []);


  return (


          <div className="wrapper">
            <div className="main-panel" ref={mainPanelRef} >

            <Helmet>
                <meta charSet="utf-8" />
                <title>Batcher</title>
                <link rel="canonical" href="http://batcher.marigold.dev" />
            </Helmet>
      <div className="content">
        <Col sm="15">
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
          <Col sm="7">
            <Row>
              <Card>
              <CardHeader>
                <h3 className="title">PAIR: tzBTC / USDT</h3>
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
                <Button className="btn-danger" color="primary" >
                        Deposit
                </Button>
                <Button className="btn-danger" color="primary">
                  Redeem
                </Button>
               {/*
                 *<Button className="btn-danger" color="primary" onClick={updateValues}>
                 *    Update
                 *</Button>
                 */}
              </CardFooter>
            </Card>
            </Row>
            <Row>
            <DepositButton
                Tezos={Tezos}
                setWallet={setWallet}
                setUserAddress={setUserAddress}
                setUserBalance={setUserBalance}
                tokenName={baseTokenName}
                tokenAddress={baseTokenAddress}
                contractAddress={contractAddress}
                tokenBalanceUri={tokenBalanceUri}
                wallet={wallet}
            />
             <DepositButton
                Tezos={Tezos}
                setWallet={setWallet}
                setUserAddress={setUserAddress}
                setUserBalance={setUserBalance}
                tokenName={quoteTokenName}
                tokenAddress={quoteTokenAddress}
                contractAddress={contractAddress}
                tokenBalanceUri={tokenBalanceUri}
                wallet={wallet}
            />
            </Row>
          </Col>
          <Col sm="1"></Col>
          <Col sm="2">
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
                        <Col className="col-3"><h6 className="title d-inline">MINUS</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("mINUS", orderBook?.bids!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-3"><h6 className="title d-inline">EXACT</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("eXACT", orderBook?.bids!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-3"><h6 className="title d-inline">PLUS</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("pLUS", orderBook?.bids!)}</Col>
                      </Row>
                   </Table>
                      
                   </Col>
                   <Col>
                    <h4 className="title d-inline">Asks</h4>
                    <Table size="sm">
                    <Row>
                        <Col className="col-3"><h6 className="title d-inline">MINUS</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("mINUS", orderBook?.asks!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-3"><h6 className="title d-inline">EXACT</h6></Col>
                        <Col className="px-sm-0">{(orderBook == undefined) ? null : get_token_by_side("eXACT", orderBook?.asks!)}</Col>
                      </Row>
                      <Row>
                        <Col className="col-3"><h6 className="title d-inline">PLUS</h6></Col>
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
        </Col>
 </div>      </div>
            </div>


  );
}

export default App;
