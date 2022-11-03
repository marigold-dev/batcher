import React, { useEffect, useState } from 'react';
import { Space, Typography, Col, Row } from 'antd';
import { useModel } from 'umi';
import '@/components/BatcherInfo/index.less';
import '@/global.less';
import { BatcherInfoProps, BatcherStatus } from '@/extra_utils/types';
import BatcherStepper from '../BatcherStepper';

const { Text } = Typography;

const BatcherInfo: React.FC<BatcherInfoProps> = ({
  buyBalance,
  sellBalance,
  inversion,
  rate,
  status,
}: BatcherInfoProps) => {
  const { initialState } = useModel('@@initialState');
  const { userAddress } = initialState;

  return (
    <div>
      <Row className="batcher-header">
        <Col lg={3} />
        <Col className="batcher-time" xs={24} lg={6}>
          <Space className="batcher-time-gap">
            <Space className="pd-0" direction="vertical">
              <Typography className="batcher-title p-16">Batcher Time Remaining</Typography>
              {status === BatcherStatus.NONE ? (
                <Typography className="batcher-title p-13">No open Batch</Typography>
              ) : (
                <BatcherStepper status={status} />
              )}
            </Space>
            <div className="batcher-time-difference">
              <Typography className="p-13">5 min</Typography>
            </div>
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
            <Typography className="batcher-title p-13">{rate} tzBTC/USDT</Typography>
          </Space>
        </Col>
        <Col lg={3} />
      </Row>
    </div>
  );
};

export default BatcherInfo;
