import React from 'react';
import '@/components/BatcherAction/index.less';
import { Button, Col, Space, Row } from 'antd';
import { BatcherActionProps, ContentType } from '@/extra_utils/types';

const BatcherAction: React.FC<BatcherActionProps> = ({ setContent }: BatcherActionProps) => {
  return (
    <div>
      <Row>
        <Col lg={3} />
        <Col lg={18} xs={24}>
          <Row className="batcher-action-outer pd-25">
            <Col lg={3} />
            <Col className="batcher-action-items" lg={18} xs={24}>
              <Space align="center">
                <Button onClick={() => setContent(ContentType.SWAP)}>Swap</Button>
                <Button onClick={() => setContent(ContentType.ORDER_BOOK)}>Order book</Button>
                <Button onClick={() => setContent(ContentType.REDEEM_HOLDING)}>Redeem holdings</Button>
              </Space>
            </Col>
            <Col lg={3} />
          </Row>
        </Col>
        <Col lg={3} />
      </Row>
    </div>
  );
};

export default BatcherAction;
