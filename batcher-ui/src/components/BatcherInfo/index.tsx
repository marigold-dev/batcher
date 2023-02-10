import React, { useEffect, useState } from 'react';
import { Space, Typography, Col, Row } from 'antd';
import { useModel } from 'umi';
import '@/components/BatcherInfo/index.less';
import '@/global.less';
import { BatcherInfoProps, BatcherStatus } from '@/extra_utils/types';
import BatcherStepper from '../BatcherStepper';
import { parseISO, add, differenceInMinutes } from 'date-fns';

const { Text } = Typography;

const BatcherInfo: React.FC<BatcherInfoProps> = ({
  tokenPair,
  buyBalance,
  sellBalance,
  buyTokenName,
  sellTokenName,
  inversion,
  rate,
  status,
  openTime,
}: BatcherInfoProps) => {
  const { initialState } = useModel('@@initialState');
  const { userAddress } = initialState;

  const get_time_difference = () => {
    if (status === BatcherStatus.OPEN && openTime) {
      const now = new Date();
      const open = parseISO(openTime);
      const batcherClose = add(open, { minutes: 10 });
      const diff = differenceInMinutes(batcherClose, now);
      return diff;
    }
    return 0;
  };

  return (
    <div>
      <Row className="batcher-header">
        <Col lg={3} />
        <Col className="batcher-time" xs={24} lg={9}>
          <Space className="batcher-time-gap">
            <Space className="pd-0" direction="vertical">
              <Typography className="batcher-title p-16">Batcher Time Remaining</Typography>
              {status === BatcherStatus.NONE ? (
                <Typography className="batcher-title p-13">No open Batch</Typography>
              ) : (
                <BatcherStepper status={status} />
              )}
            </Space>
            {status === BatcherStatus.OPEN ? (
              <div className="batcher-time-difference">
                <Typography className="p-13">{get_time_difference() + ' min'}</Typography>
              </div>
            ) : (
              <div />
            )}
          </Space>
        </Col>
        <Col className="batcher-balance" xs={24} lg={9}>
          <Col className="batcher-balance-title" span={24}>
            <Space className="pd-0">
              <Typography className="batcher-title p-16">Balance</Typography>
              <Typography className="batcher-title p-13">
                {inversion
                  ? buyBalance.balance + ' ' + buyTokenName
                  : sellBalance.balance + ' ' + sellTokenName}
              </Typography>
            </Space>
          </Col>
          <Col className="batcher-balance-amount" span={24}>
            <Space className="pd-0">
              <Typography className="batcher-title p-16">Address</Typography>
              {userAddress ? (
                <Text style={{ width: 150 }} ellipsis={{ tooltip: userAddress }}>
                  {userAddress}
                </Text>
              ) : (
                <Text className="batcher-title p-13">No Wallet connected</Text>
              )}
            </Space>
          </Col>
          <Col className="batcher-price" span={24}>
            <Space className="pd-0">
              <Typography className="batcher-title p-16">Oracle Price</Typography>
              <Typography className="batcher-title p-13">{rate} {tokenPair}</Typography>
            </Space>
          </Col>
        </Col>
        <Col lg={3} />
      </Row>
    </div>
  );
};

export default BatcherInfo;
