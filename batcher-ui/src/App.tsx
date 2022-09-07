import React from 'react';
import logo from './logo.svg';
import marigoldlogo from './marigoldlogo.png';
import { useState } from 'react';
import ConnectButton from './ConnectWallet';
import { TezosToolkit, WalletContract } from '@taquito/taquito';
import DisconnectButton from './DisconnectWallet';
import { Contract, ContractsService } from '@dipdup/tzkt-api';
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
  const [wallet, setWallet] = useState<any>(null);
  const [userAddress, setUserAddress] = useState<string>("");
  const [userBalance, setUserBalance] = useState<number>(0);
  const mainPanelRef = React.useRef(null);
  const sidebarRef = React.useRef(null);



  return (
          <div className="wrapper">
            <div className="main-panel" ref={mainPanelRef} >

      <div className="content">
        <Row>
          <Col xs="11">
            <Card className="card-chart">
              <CardHeader>
                  <Col className="text-left float-left" sm="4">
                    <CardTitle tag="h1"><img src={logo} height="200" alt="logo"/></CardTitle>
                  </Col>
                  <Col className="text-right float-right" sm="4">
                    <CardTitle tag="h1"><img src={marigoldlogo} height="200" alt="logo"/></CardTitle>
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
                <h3 className="title">TZBTC / USDT</h3>
              </CardHeader>
              <CardBody>
                 <Row>
                   <Col sm="2">
                      <h4 className="title d-inline">Oracle Price</h4>
                      <p className="description bold">1:21000</p>
                     </Col>
                   <Col sm="2">
                      <h4 className="title d-inline">Time Remaining in Current Batch</h4>
                      <p className="description bold">2 mins</p>
                     </Col>
                   <Col sm="2">
                      <h4 className="title d-inline">Buy Orders in Current Batch</h4>
                      <p className="description bold">10</p>
                     </Col>
                   <Col sm="2">
                      <h4 className="title d-inline">Sell orders in Current Batch</h4>
                      <p className="description bold">23</p>
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
              </CardFooter>
            </Card>
          </Col>
          <Col md="4">
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
          </Col>
        </Row>

 </div>      </div>
            </div>


  );
}

export default App;
