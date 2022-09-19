import React from 'react';
import logo from './logo.svg';
import marigoldlogo from './marigoldlogo.png';
import { useState } from 'react';
import ConnectButton from './ConnectWallet';
import { TezosToolkit, WalletContract, MichelsonMap } from '@taquito/taquito';
import DisconnectButton from './DisconnectWallet';
import { Contract, ContractsService, MichelineFormat } from '@dipdup/tzkt-api';
import classNames from "classnames";
import { Nav, NavLink as ReactstrapNavLink } from "reactstrap";
import { format, formatDistance, formatRelative, subDays, parseISO, add, sub, differenceInMilliseconds, differenceInMinutes } from 'date-fns'
import './App.css';
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
  const [userAddress, setUserAddress] = useState<string>("");
  const [userBalance, setUserBalance] = useState<number>(0);
  const mainPanelRef = React.useRef(null);
  const sidebarRef = React.useRef(null);
  const [exchangeRate, setExchangeRate] = useState<number | undefined>();
  const [stringStorage, setStringStorage] = useState<string>("");
  const [remaining, setRemaining] = useState<string>("");
  const [orderBook, setOrderBook] = useState<order_book | undefined>();
  const [numberOfBids, setNumberOrBids] = useState<number>(0);
  const [numberOfAsks, setNumberOrAsks] = useState<number>(0);
  const [storage, setStorage] = useState<ContractStorage | undefined>();
   //tzkt
  const contractsService = new ContractsService( {baseUrl: "https://api.jakartanet.tzkt.io" , version : "", withCredentials : false});
  
  const contractAddress: string = "KT1PyZqjjEJrorcxUg7mNnHeE2ZwNVApCniz";
  const tokenBTCaddress: string = "KT1XBUuCDb7ruPcLCpHz4vrh9jL9ogRFYTpr"
  const tokenUSDTaddress: string = "KT1AqXVEApbizK6ko4RqtCVdgw8CQd1xaLsF"
  const pair = "tzBTC/USDT"
  const inverted_pair = "USDT/tzBTC"

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

  const update_from_storage = async () => {
    const tcontract =  await Tezos.contract.at(contractAddress);
    const storage = await contractsService.getStorage( { address : contractAddress, level: 0, path: null } );
    const rates_map = await contractsService.getBigMapByName( { address : contractAddress, name: "rates_current", micheline: MichelineFormat.JSON } );
    const rates_map_keys = await contractsService.getBigMapByNameKeys( { address : contractAddress, name: "rates_current", micheline: MichelineFormat.JSON } )
    const exchange_rate : exchange_rate = rates_map_keys.filter(r => r.key == inverted_pair)[0].value;
    const scaled_rate = rationalise_rate(exchange_rate.rate.val, exchange_rate.swap.to.decimals, exchange_rate.swap.from.token.decimals);
    setExchangeRate(scaled_rate);

    const current_batch_status:batch_status = await storage.batches.current.status;
    const time_remaining = get_time_left_in_batch(current_batch_status);
    setRemaining(time_remaining);

    const order_book : order_book = await storage.batches.current.orderbook;
    setOrderBook(order_book);
    setStringStorage(JSON.stringify(order_book));
    setNumberOrBids(order_book.bids.length);
    setNumberOrAsks(order_book.asks.length);

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

  updateValues();

  return (
          <div className="wrapper">
            <div className="main-panel" ref={mainPanelRef} >

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
          <Col md="7">
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
               <Button className="btn-danger" color="primary" onClick={updateValues}>
                   Update
               </Button>
              </CardFooter>
            </Card>
          </Col>
          <Col md="4">
            <Row>
            <Card className="card-user">
              <CardBody>
                <CardText />
                <div className="author">
                  <div className="block block-one" />
                  <div className="block block-two" />
                  <div className="block block-three" />
                  <div className="block block-four" />
                  <p className="description">{userAddress}</p>
                </div>
                <div className="card-description">
                  {userBalance}
                </div>
              </CardBody>
              <CardFooter>
                <div className="button-container">
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
                   <Col sm="2">
                    <h4 className="title d-inline">Bids</h4>
                    <Table size="sm">
                   { 
                     orderBook?.bids.map(b => <tr>{b.tolerance.toString()}</tr>) 
                    }
                   </Table>
                      
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
               <Button className="btn-danger" color="primary" onClick={updateValues}>
                   Update
               </Button>
              </CardFooter>
            </Card>
            </Row>
          </Col>
        </Row>

 </div>      </div>
            </div>


  );
}

export default App;
