import React, { useEffect, useState } from 'react';
import { Button, Space, Typography, Col, Row, Table } from 'antd';
import '@/global.less';
const { Text, Paragraph } = Typography;

const About: React.FC = () => {
  return (
    <div>
     <Space direction="vertical">
       <Paragraph strong>Batcher is a batch processing orderbook DEX.  This means that all orders for potential swaps between two pairs of tokens are collected over a finite period (currently 10 minutes) and then the batch is closed to additions. Batcher then waits for the next Oracle price for the token pair and then looks to match the maximum amount of orders at the fairest possible price.
       </Paragraph>
       <Paragraph strong>
Batcher’s goal is to enable users to deposit tokens with the aim of being swapped at a <Text italic>fair price</Text> with <Text italic>bounded slippage</Text> and almost no <Text italic>impermanent loss</Text>.
To do so, users will deposit tokens during a <Text italic>deposit window</Text>; all deposits during this window will be a <Text italic>'batch'</Text>.
The batch is locked, waiting for an <Text italic>oracle price</Text>. When the later is received, the batch is terminated and the <Text italic>orders</Text> are cleared wherein Batcher will attempt to maximise the number of orders cleared.
        </Paragraph>
        <Paragraph strong>
For V1, the <Text italic>deposit window</Text> will be 10 mins and then a wait time of 2 minutes before awaiting the oracle price. Only the <Text italic>tzBTC/USDT</Text> pair will be supported for V1.
        </Paragraph>
        <Paragraph strong>
Note: Batcher can deal with token value imbalance which means that holders of <Text italic>tzBTC</Text> and holders of <Text italic>USDT</Text> can swap different amounts as long as the market of <Text italic>orders</Text> is equivalent on both sides.
     </Paragraph>
     </Space>
    </div>
  );
};

export default About;
