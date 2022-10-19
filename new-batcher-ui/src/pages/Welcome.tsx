import { SwapOutlined, UpOutlined, DownOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row, InputNumber } from 'antd';
import React from 'react';

const Welcome: React.FC = () => {
  return (
    <div>
      <Row className="batcher-header">
        <Col lg={3} />
        <Col className="batcher-time" xs={24} lg={6}>
          <Space direction="vertical">
            <Typography className="batcher-title p-16">Batcher Time Remaining</Typography>
            <Typography className="batcher-title p-13">Open Batch</Typography>
          </Space>
        </Col>
        <Col className="batcher-balance" xs={24} lg={6}>
          <Col className="batcher-balance-title" span={24}>
            <Typography className="batcher-title p-16">Balance</Typography>
          </Col>
          <Col className="batcher-balance-amount" span={24}>
            <Typography className="batcher-title p-16">Address No wallet connected</Typography>
          </Col>
        </Col>
        <Col className="batcher-oracle" xs={24} lg={6}>
          <Space>
            <Typography className="batcher-title p-16">Oracle Price</Typography>
            <Typography className="batcher-title p-13">0 tzBTC/USDT</Typography>
          </Space>
        </Col>
        <Col lg={3} />
      </Row>
      <Row className="batcher-content">
        <Col lg={3} />
        <Col className="br-t br-b br-l br-r" xs={24} lg={18}>
          <Row>
            <Col lg={3} />
            <Col xs={24} lg={18} className="pd-25">
              <Col className="base-content br-t br-b br-l br-r">
                <Space className="batcher-price" direction="vertical">
                  <Space size="large">
                    <Typography className="batcher-title p-16">From tzBTC</Typography>
                    <Input className="batcher-token" placeholder="Amount" />
                  </Space>
                  <Typography className="batcher-title p-13">
                    Select the price you want to sell
                  </Typography>
                  <Row className="text-center">
                    <Col className="batcher-title pd-5 br-t br-l br-b" span={8}>
                      <Typography className="p-12">Worse price / Better fill</Typography>
                    </Col>
                    <Col className="batcher-title pd-5 br-t br-b br-l br-r" span={8}>
                      <Typography className="p-12">Oracle Price</Typography>
                    </Col>
                    <Col className="batcher-title pd-5 br-t br-b br-r" span={8}>
                      <Typography className="p-12">Better Price / Worse Fill</Typography>
                    </Col>
                  </Row>
                </Space>
              </Col>
              <SwapOutlined className="exchange-button grid-padding" rotate={90} />
              <Col className="quote-content grid-padding br-t br-b br-l br-r">
                <Typography className="batcher-title p-16">To USDT</Typography>
              </Col>
              <div className="tx-align">
                <Button className="mt-25" type="primary" danger>
                  Try to swap
                </Button>
              </div>
            </Col>
            <Col lg={3} />
          </Row>
        </Col>
        <Col lg={3} />
      </Row>
    </div>
  );
};

export default Welcome;
