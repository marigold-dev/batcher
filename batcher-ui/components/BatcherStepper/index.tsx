import React, { useEffect, useState } from 'react';
import { Space, Typography } from 'antd';
// import './index.less';
import { BatcherStatus, BatcherStepperProps } from '../../extra_utils/types';

const BatcherStepper: React.FC<BatcherStepperProps> = ({ status }: BatcherStepperProps) => {
  return (
    <div>
      <Space className="pd-5-10">
        <Space className="batcher-started pd-0">
          <div className={status !== BatcherStatus.NONE ? 'green-color' : 'gray-color'}>null</div>
          <Space className={status !== BatcherStatus.NONE ? 'pd-0 green-dot' : 'pd-0 gray-dot'}>
            <div className="batcher-dot">-</div>
            <div className="batcher-dot">-</div>
            <div className="batcher-dot">-</div>
          </Space>
        </Space>
        <Space className="batcher-closed pd-0">
          <div
            className={
              status === BatcherStatus.CLOSED || status === BatcherStatus.CLEARED
                ? 'green-color'
                : 'gray-color'
            }
          >
            null
          </div>
          <Space className={status === BatcherStatus.CLEARED ? 'pd-0 green-dot' : 'pd-0 gray-dot'}>
            <div className="batcher-dot">-</div>
            <div className="batcher-dot">-</div>
            <div className="batcher-dot">-</div>
          </Space>
        </Space>
        <Space className="batcher-cleared pd-0">
          <div
            className={status === BatcherStatus.CLEARED ? 'pd-0 green-color' : 'pd-0 gray-color'}
          >
            null
          </div>
        </Space>
      </Space>
      <Space className="batcher-stepper-gap pd-0">
        <Typography>Started</Typography>
        <Typography>Closed</Typography>
        <Typography>Cleared</Typography>
      </Space>
    </div>
  );
};

export default BatcherStepper;
