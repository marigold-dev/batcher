import React, { useEffect } from 'react';
import { Button, Space, Typography, Col, message } from 'antd';
import '@/components/Exchange/index.less';
import '@/components/Holdings/index.less';
import '@/global.less';
import { HoldingsProps } from '@/extra_utils/types';

const Holdings: React.FC<HoldingsProps> = ({
  tezos,
  userAddress,
  contractAddress,
  buyToken,
  sellToken,
  buyTokenHolding,
  sellTokenHolding,
  setBuySideAmount,
  setSellSideAmount,
}: HoldingsProps) => {
  const redeemHoldings = async (): Promise<void> => {
    let loading = function () {
      return undefined;
    };

    try {
      const contractWallet = await tezos.wallet.at(contractAddress);
      let redeem_op = await contractWallet.methods.redeem().send();

      if (redeem_op) {
        loading = message.loading('Attempting to redeem holdings...', 0);
        const confirm = await redeem_op.confirmation();
        if (!confirm.completed) {
          message.error('Failed to redeem holdings');
          console.error('Failed to redeem holdings' + confirm);
        } else {
          setSellSideAmount(0);
          setBuySideAmount(0);
          loading();
          message.success('Successfully redeemed holdings');
        }
      } else {
        throw new Error('Failed to redeem tokens');
      }
    } catch (error: any) {
      loading();
      message.error('Unable to redeem holdings : ' + error.message);
      console.error('Unable to redeem holdings' + error);
    }
  };

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
          <Button className="btn-content mtb-25" type="primary" onClick={redeemHoldings} danger>
            Redeem
          </Button>
        </Col>
      </Space>
    </Col>
  );
};

export default Holdings;
