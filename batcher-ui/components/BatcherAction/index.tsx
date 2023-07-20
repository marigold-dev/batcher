import React from 'react';
// import '../index.less';
// import '../../src/global.less';
import { Button, Col, Space, Row, Typography, Drawer, Radio } from 'antd';
import { BatcherActionProps, ContentType } from '../../extra_utils/types';

const { Text } = Typography;

const BatcherAction: React.FC<BatcherActionProps> = ({
  content,
  setContent,
}: BatcherActionProps) => {
  return (
    <div>
      <Row>
        <Col lg={3} />
        <Col lg={18} xs={24}>
          <Row className="batcher-action-outer">
            <Col lg={3} />
            <Col className="batcher-action-items" lg={18} xs={24}>
              <Space align="center">
                <Button className="batcher-nav-btn" onClick={() => setContent(ContentType.SWAP)}>
                  <Text underline>Swap</Text>
                </Button>
                <Button className="batcher-nav-btn" onClick={() => setContent(ContentType.VOLUME)}>
                  <Text underline>Volume</Text>
                </Button>
                <Button
                  className="batcher-nav-btn"
                  onClick={() => setContent(ContentType.REDEEM_HOLDING)}
                >
                  <Text underline>Redeem Holdings</Text>
                </Button>
                <Button className="batcher-nav-btn" onClick={() => setContent(ContentType.ABOUT)}>
                  <Text underline>About</Text>
                </Button>
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
