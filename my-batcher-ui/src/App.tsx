import React from "react";
import { Button, Layout, Typography, Image, Col, Row } from "antd";
import BatcherLogo from "./img/batcher-logo.png";
import MarigoldLogo from "./img/marigold-logo.png";
import "./App.scss";

const { Header, Content, Footer } = Layout;
const { Title } = Typography;

const App = () => (
  <div className="App">
    <Header>
      <Col className="left-header" span={20}>
        <Image src={BatcherLogo} width={75} />
        <div className="header-title">
          <Title level={5}>BATCHER</Title>
        </div>
      </Col>
      <Col span={4}>
        <Button className="typical-button" type="primary" size="large">
          Connect Wallet
        </Button>
      </Col>
    </Header>
    <Content>fffff</Content>
    <Footer>
      <Col className="left-header" span={20}>
        <Title level={5}>MARIGOLD</Title>
        <Image src={MarigoldLogo} width={75} />
      </Col>
    </Footer>
  </div>
);

export default App;
