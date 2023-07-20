import React, { useState, useEffect, useContext } from 'react';
import { Button, Space, Typography, Col, message, Table } from 'antd';
// import '../Exchange/index.less';
// import './index.less';
// import '../../src/global.less';
import { HoldingsProps } from '../../extra_utils/types';
import { zeroHoldings } from '../../extra_utils/utils';
import { AppStateContext } from '../../contexts';
import { TezosToolkitContext } from '../../contexts/tezos-toolkit';
const Holdings: React.FC<HoldingsProps> = ({
  contractAddress,
  openHoldings,
  clearedHoldings,
  setOpenHoldings,
  setClearedHoldings,
  updateAll,
  setUpdateAll,
  hasClearedHoldings,
}: HoldingsProps) => {
  const state = useContext(AppStateContext);
  const { connection } = useContext(TezosToolkitContext);

  const triggerUpdate = () => {
    setTimeout(function () {
      const u = !updateAll;
      setUpdateAll(u);
    }, 5000);
  };

  const generateHoldings = (dict: Map<string, number>) => {
    const data: { token: string; holding: number }[] = [];

    for (const key of dict) {
      data.push({
        token: key[0],
        holding: key[1],
      });
    }
    return (
      <>
        {data.map((h) => (
          <React.Fragment key={h.token}>
            <Typography>
              {' '}
              {h.holding} {h.token} |{' '}
            </Typography>
          </React.Fragment>
        ))}
      </>
    );
  };

  const redeemHoldings = async (): Promise<void> => {
    try {
      connection.setWalletProvider(state.wallet);
      const contractWallet = await connection.wallet.at(contractAddress);
      let redeem_op = await contractWallet.methods.redeem().send();

      if (redeem_op) {
        message.loading('Attempting to redeem holdings...', 0);
        const confirm = await redeem_op.confirmation();
        if (!confirm.completed) {
          message.error('Failed to redeem holdings');
          console.error('Failed to redeem holdings' + confirm);
        } else {
          setOpenHoldings(new Map<string, number>());
          setClearedHoldings(new Map<string, number>());
          message.loading('Attempting to redeem holdings...', 0);
          message.success('Successfully redeemed holdings');
          triggerUpdate();
        }
      } else {
        throw new Error('Failed to redeem tokens');
      }
    } catch (error: any) {
      // loading();
      message.error('Unable to redeem holdings : ' + error.message);
      console.error('Unable to redeem holdings' + error);
    }
  };

  return (
    <Col className="base-content br-t br-b br-l br-r">
      <Space className="batcher-price" direction="vertical">
        <Typography className="batcher-title p-16">Open/Closed Batches</Typography>
        <Col className="batcher-holding-content br-t br-b br-l br-r pd-25 tx-align" span={24}>
          <Space direction="horizontal">
            <Typography>Holdings =&gt; </Typography>| {generateHoldings(openHoldings)}
          </Space>
        </Col>
      </Space>
      <Space className="batcher-price" direction="vertical">
        <Typography className="batcher-title p-16">Cleared Batches (Redeemable)</Typography>
        <Col className="batcher-holding-content br-t br-b br-l br-r pd-25 tx-align" span={24}>
          <Space direction="horizontal">
            <Typography>Holdings =&gt; </Typography>
            {generateHoldings(clearedHoldings)}
          </Space>
        </Col>
      </Space>
      <Space className="batcher-price" direction="vertical">
        <Col className="batcher-redeem-btn">
          {hasClearedHoldings ? (
            <Button className="btn-content mtb-25" type="primary" onClick={redeemHoldings} danger>
              Redeem
            </Button>
          ) : (
            <div></div>
          )}
        </Col>
      </Space>
    </Col>
  );
};

export default Holdings;
