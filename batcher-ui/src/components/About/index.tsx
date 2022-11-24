import React, { useEffect, useState } from 'react';
import { Button, Space, Typography, Col, Row, Table, Anchor } from 'antd';
import '@/global.less';
const { Text, Paragraph } = Typography;
const { Link } = Anchor;
const About: React.FC = () => {
  return (
    <div>
     <Space direction="vertical">
       <Paragraph strong>Batcher is a batch processing orderbook DEX.  Batcher’s goal is to enable users to deposit tokens with the aim of being swapped at a <Text italic>fair price</Text> with <Text italic>bounded slippage</Text> and almost no <Text italic>impermanent loss</Text>. This means that all orders for potential swaps between two pairs of tokens are collected over a finite period (currently 10 minutes). This is deemed the 'batch'.  After the order collection period is over, the batch is closed to additions. Batcher then waits for the next Oracle price for the token pair.  When this is received, the batch is terminated and then Batcher looks to match the maximum amount of orders at the fairest possible price.
       </Paragraph>
        <Paragraph strong>
For V1, the <Text italic>deposit window</Text> will be 10 mins and then a wait time of 2 minutes before awaiting the oracle price. Only the <Text italic>tzBTC/USDT</Text> pair will be supported for V1.
        </Paragraph>
        <Paragraph strong>
Note: Batcher can deal with token value imbalance which means that holders of <Text italic>tzBTC</Text> and holders of <Text italic>USDT</Text> can swap different amounts as long as the market of <Text italic>orders</Text> is equivalent on both sides.
     </Paragraph>
     <Paragraph strong>

      <Link href="https://www.youtube.com/watch?v=P1Ohe4vCPRI&list=PLtUU5fjvCugpap87nNp95txM23m2DNz_H" title="Batcher Video Playlist" />
     </Paragraph>
     </Space>
    </div>
  );
};

export default About;
