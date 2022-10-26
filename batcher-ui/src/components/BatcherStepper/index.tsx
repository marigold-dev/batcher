import React from 'react';
import { Image, Space, Steps, Typography } from 'antd';
import { MinusCircleFilled } from '@ant-design/icons';
import '@/components/BatcherStepper/index.less';

const SquareIcon = (
  <div>
    <svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect width="15" height="15" fill="#CECCCC" />
    </svg>
  </div>
);

const { Step } = Steps;
const BatcherStepper: React.FC = () => {
  return (
    <div>
      <Space className="pd-5-10">
        <Space className="batcher-started pd-0">
          <div className="gray-color">null</div>
          <Space className="pd-0">
            <div className="batcher-dot">-</div>
            <div className="batcher-dot">-</div>
            <div className="batcher-dot">-</div>
          </Space>
        </Space>
        <Space className="batcher-closed pd-0">
          <div className="gray-color">null</div>
          <Space className="pd-0">
            <div className="batcher-dot">-</div>
            <div className="batcher-dot">-</div>
            <div className="batcher-dot">-</div>
          </Space>
        </Space>
        <Space className="batcher-cleared pd-0">
          <div className="gray-color">null</div>
        </Space>
      </Space>
      <Space className="batcher-stepper-gap pd-0">
        <Typography>Started</Typography>
        <Typography>Cleared</Typography>
        <Typography>Closed</Typography>
      </Space>
    </div>
  );
};

export default BatcherStepper;
