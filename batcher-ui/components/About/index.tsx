import React from 'react';
import { Space, Typography, Anchor } from 'antd';
// import '../../src/global.less';

const { Text, Paragraph } = Typography;
const { Link } = Anchor;

const About: React.FC<{}> = () => {
  return (
    <div>
      <Space direction="vertical">
        <Paragraph strong>
          Batcher is a new type of DEX that we have named a 'batch clearing DEX'. It provides a dark
          pool-like trading environment without using liquidity pools or having the issue of
          significant slippage. Batcher’s goal is to enable users to deposit tokens with the aim of
          being swapped at a <Text italic>fair price</Text> with{' '}
          <Text italic>bounded slippage</Text> and almost no <Text italic>impermanent loss</Text>.
          This means that all orders for potential swaps between two pairs of tokens are collected
          over a finite period (currently 10 minutes). This is deemed the 'batch'. After the order
          collection period is over, the batch is closed to additions. Batcher then waits for the
          next Oracle price for the token pair. When this is received, the batch is terminated and
          then Batcher looks to match the maximum amount of orders at the fairest possible price.
        </Paragraph>
        <Paragraph strong>
          For V1, the <Text italic>deposit window</Text> will be 10 mins and then a wait time of 2
          minutes before awaiting the oracle price.
        </Paragraph>
        <Paragraph strong>
          Note: Batcher can deal with token value imbalance which means that holders of{' '}
          <Text italic>tzBTC</Text> and holders of <Text italic>USDT</Text> can swap different
          amounts as long as there is a market for the <Text italic>trade</Text> on both sides.
        </Paragraph>
        <Paragraph strong>
          Batcher has been designed to be composable with other high liquidity paths in the Tezos
          ecosystem, specifically the Sirius DEX; thus, the two pairs that are supported in V1 are
          tzBTC/USDT and tzBTC/EURL.
        </Paragraph>
        <Paragraph strong>
          For more information including blog posts and faqs, please visit the Batcher project page
          at Marigold.dev.
          <Link href="https://www.marigold.dev/batcher" title="Batcher Project Page" />
        </Paragraph>
        <Paragraph>
          <Text strong> *DISCLAIMER:*</Text>
          <Text italic>
            {' '}
            All investing comes with risk and DeFi is no exception. The content in this Dapp
            contains no financial advice. Please do your own thorough research and note that all
            users funds are traded at their own risk. No reimbursement will be made and Marigold
            will not assume responsibility for any losses.{' '}
          </Text>
        </Paragraph>
      </Space>
    </div>
  );
};

export default About;
