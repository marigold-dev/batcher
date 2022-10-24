import React from 'react';
import {  Space, Typography, Col, Row } from 'antd';
import { useModel } from 'umi';
import '@/components/BatcherInfo/index.less';
import '@/global.less';
import { BatcherInfoProps } from '@/extra_utils/types';

const { Text } = Typography;

const BatcherInfo: React.FC<BatcherInfoProps> = ({ buyBalance, sellBalance, inversion }: BatcherInfoProps) => {
  const { initialState } = useModel('@@initialState');
  const { wallet, userAddress } = initialState;

  return (
    <div>
      <Row className="batcher-header">
        <Col lg={3} />
        <Col className="batcher-time" xs={24} lg={6}>
          <Space direction="vertical">
            <Typography className="batcher-title p-16">Batcher Time Remaining</Typography>
            <Typography className="batcher-title p-13">No open Batch</Typography>
          </Space>
        </Col>
        <Col className="batcher-balance" xs={24} lg={6}>
          <Col className="batcher-balance-title" span={24}>
            <Space className="pd-0">
              <Typography className="batcher-title p-16">Balance</Typography>
              <Typography className="batcher-title p-13">
                {inversion
                  ? buyBalance.balance + ' ' + buyBalance.token.name
                  : sellBalance.balance + ' ' + sellBalance.token.name}
              </Typography>
            </Space>
          </Col>
          <Col className="batcher-balance-amount" span={24}>
            <Space className="pd-0">
              <Typography>Address</Typography>
              {userAddress ? (
                <Text style={{ width: 150 }} ellipsis={{ tooltip: userAddress }}>
                  {userAddress}
                </Text>
              ) : (
                <Text className="batcher-title p-13">No Wallet connected</Text>
              )}
            </Space>
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
    </div>
  );
};

export default BatcherInfo;
