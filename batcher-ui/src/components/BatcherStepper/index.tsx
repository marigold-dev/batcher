import React from 'react';
import { Space, Typography } from 'antd';
import '@/components/BatcherStepper/index.less';

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
