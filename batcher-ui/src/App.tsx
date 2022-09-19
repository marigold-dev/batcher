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


function App() {

  const [Tezos, setTezos] = useState<TezosToolkit>(new TezosToolkit("https://jakartanet.tezos.marigold.dev"));
  class token {
   name!: string;
   address!: string;
   decimals!:BigInt; 
  }

  class side {

  }

  class token_amount {
    token!: token;
    amount!: BigInt;
  }

  class swap {
     from!: token_amount;
     to!: token; 
  }

  class exchange_rate {
     swap!: swap;
     rate!: number;
     when!: string;
  }

  class swap_order {
    trader!: string;
    swap!: swap;
    created_at!: string;
    side!: string;
    tolerance!: string;
  }

  class order_book {
    bids!: Array<swap_order>;
    asks!: Array<swap_order>;
  }

  class token_holding {
    holder!:string;
    token_amount!: token_amount;

  }
  class batch {
      status!: string;
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
  const [exchangeRate, setExchangeRate] = useState<exchange_rate | undefined>();
  const [stringStorage, setStringStorage] = useState<string>("");

  const [numberOfBids, setNumberOrBids] = useState<number>(0);
  const [numberOfAsks, setNumberOrAsks] = useState<number>(0);
  const [storage, setStorage] = useState<ContractStorage | undefined>();
   //tzkt
  const contractsService = new ContractsService( {baseUrl: "https://api.jakartanet.tzkt.io" , version : "", withCredentials : false});
  
  const contractAddress: string = "KT1PyZqjjEJrorcxUg7mNnHeE2ZwNVApCniz";
  const tokenBTCaddress: string = "KT1XBUuCDb7ruPcLCpHz4vrh9jL9ogRFYTpr"
  const tokenUSDTaddress: string = "KT1AqXVEApbizK6ko4RqtCVdgw8CQd1xaLsF"
  const pair = "tzBTC/USDT"



  const update_from_storage = async () => {
    const tcontract =  await Tezos.contract.at(contractAddress);
    const cstorage = await contractsService.getStorage( { address : contractAddress, level: 0, path: null } );
    const rates = await contractsService.getBigMapByName( { address : contractAddress, name: "rates_current", micheline: MichelineFormat.JSON } );
    const storage = cstorage.storage;
   // const storage:ContractStorage= await contract.storage();
    setStringStorage(JSON.stringify(storage));
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
                      <p className="description bold">{ exchangeRate?.when }</p>
                     </Col>
                   <Col sm="2">
                      <h4 className="title d-inline">Time Remaining in Current Batch</h4>
                      <p className="description bold">2 mins</p>
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
                <h3 className="title">Exchange Rates</h3>
              </CardHeader>
              <CardBody>
                 <Row>
                   <Col sm="4">
                   { 
                  
                  }
                
                      
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
