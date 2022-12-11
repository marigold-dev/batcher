import React, { useEffect, useState } from 'react';
import { Button, Space, Typography, Col, message } from 'antd';
import '@/components/Exchange/index.less';
import '@/components/Holdings/index.less';
import '@/global.less';
import { HoldingsProps, NewHoldingsProps, token_amount } from '@/extra_utils/types';
import { scaleAmountDown } from '@/extra_utils/utils';
import { JSONPath } from 'jsonpath-plus';

const NewHoldings: React.FC<NewHoldingsProps> = ({
  tezos,
  userAddress,
  contractAddress,
  buyToken,
  sellToken,
  buyTokenHolding,
  sellTokenHolding,
}: NewHoldingsProps) => {
  useEffect(() => {
    console.log('Address', userAddress);
  }, [userAddress]);

  return (
    <Col className="base-content br-t br-b br-l br-r">
      <Space className="batcher-price" direction="vertical">
        <Typography className="batcher-title p-16">Holdings</Typography>
        <Col className="batcher-holding-content br-t br-b br-l br-r pd-25 tx-align" span={24}>
          <Space direction="vertical">
            <Typography>
              {buyTokenHolding} {buyToken.name}
            </Typography>
            <Typography>
              {sellTokenHolding} {sellToken.name}
            </Typography>
          </Space>
        </Col>
        <Col className="batcher-redeem-btn">
          <Button className="btn-content mtb-25" type="primary" onClick={null} danger>
            Redeem
          </Button>
        </Col>
      </Space>
    </Col>
  );
};

export default NewHoldings;
