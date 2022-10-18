import { PageContainer } from '@ant-design/pro-components';
import { Alert, Button, Card, InputNumber, List, Space, Typography, Col, Row } from 'antd';
import React from 'react';
import { FormattedMessage, useIntl } from 'umi';

const Welcome: React.FC = () => {
  const gridStyle: React.CSSProperties = {
    textAlign: 'center',
    border: '3px solid #7B7B7E',
  };

  const gridHomeStyle: React.CSSProperties = {
    width: '100%',
    textAlign: 'center',
    border: '3px solid #7B7B7E',
  };

  return (
    <Row>
      <Col xs={24} lg={8} style={gridStyle}>
        <Space direction="vertical">
          <Typography>Batcher Time Remaining</Typography>
          <Typography>Open Batch</Typography>
        </Space>
      </Col>
      <Col xs={24} lg={8} style={gridStyle}>
        <Space direction="vertical">
          <Typography>Balance</Typography>
          <Typography>Address No wallet connected</Typography>
        </Space>
      </Col>
      <Col xs={24} lg={8} style={gridStyle}>
        <Space direction="vertical">
          <Typography>Oracle Price</Typography>
          <Typography>0 tzBTC/USDT</Typography>
        </Space>
      </Col>
      <Col span={24} style={gridStyle}>
        <Space direction="vertical">
          <Col style={gridHomeStyle}>
            <Space direction="vertical">
              <Space>
                <Typography>From tzBTC</Typography>
                <InputNumber />
              </Space>
              <Typography>Select the price you want to sell</Typography>
              <Row>
                <Col span={8} style={gridStyle}>
                  <Typography>Worse price / Better fill</Typography>
                </Col>
                <Col span={8} style={gridStyle}>
                  <Typography>Oracle Price</Typography>
                </Col>
                <Col span={8} style={gridStyle}>
                  <Typography>Better Price / Worse Fill</Typography>
                </Col>
              </Row>
            </Space>
          </Col>
          <Col style={gridHomeStyle}>
            <Typography>To USDT</Typography>
          </Col>
          <Button type="primary" danger>
            Try to swap
          </Button>
        </Space>
      </Col>
    </Row>
  );
};

export default Welcome;
