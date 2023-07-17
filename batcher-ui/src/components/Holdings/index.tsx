import React, { useState, useEffect, useContext } from 'react';
import { Button, Space, Typography, Col, message, Table } from 'antd';
import '@/components/Exchange/index.less';
import '@/components/Holdings/index.less';
import '@/global.less';
import { HoldingsProps, holding } from '@/extra_utils/types';
import { useModel } from 'umi';
import { zeroHoldings } from '@/extra_utils/utils';
const Holdings: React.FC<HoldingsProps> = ({
  tezos,
  contractAddress,
  openHoldings,
  closedHoldings,
  clearedHoldings,
  setOpenHoldings,
  setClearedHoldings,
  updateAll,
  setUpdateAll,
  hasClearedHoldings,
  hasClosedHoldings,
  hasOpenHoldings,
  tokenMap,
}: HoldingsProps) => {
  const { initialState } = useModel('@@initialState');

  const triggerUpdate = () => {
    setTimeout(function () {
      const u = !updateAll;
      setUpdateAll(u);
    }, 5000);
  };

  const generateHoldings = (dict: Map<string, holding>) => {
    var data = [];

    for (const key of dict) {
      let buyHolding = key[1].buy_token_holding;
      let sellHolding = key[1].sell_token_holding;
      if(buyHolding > 0 || sellHolding > 0 ){
      data.push({
        pair: key[0],
        buySideHolding: buyHolding,
        sellSideHolding: sellHolding,
      });
      };
    }

    return data;
  };

  const listOfColumnsWithCancel = [
    {
      title: 'Pair',
      key: 'pair',
      dataIndex: 'pair',
    },
    {
      title: 'Buy Side Holding',
      key: 'buySideHolding',
      dataIndex: 'buySideHolding',
    },
    {
      title: 'Sell Side Holding',
      key: 'sellSideHolding',
      dataIndex: 'sellSideHolding',
    },
    {
      title: 'Cancel Orders?',
      key: 'cancel',
      dataIndex: 'cancel',
    },
  ];
  const listOfColumns = [
    {
      title: 'Pair',
      key: 'pair',
      dataIndex: 'pair',
    },
    {
      title: 'Buy Side Holding',
      key: 'buySideHolding',
      dataIndex: 'buySideHolding',
    },
    {
      title: 'Sell Side Holding',
      key: 'sellSideHolding',
      dataIndex: 'sellSideHolding',
    },
  ];

  const generateCancelButton = (pair: string) => {
    return (
      <>
          <React.Fragment key={pair}>
            <Button className="btn-content mtb-10" type="primary" onClick={() => cancelHoldings(pair)} danger>Cancel</Button>
          </React.Fragment>
      </>
    );
  };

  const generateOpenHoldings = (dict: Map<string, holding>) => {
    var data = [];

    for (const key of dict) {
      let buyHolding = key[1].buy_token_holding;
      let sellHolding = key[1].sell_token_holding;
      if(buyHolding > 0 || sellHolding > 0 ){
      data.push({
        pair: key[0],
        buySideHolding: buyHolding,
        sellSideHolding: sellHolding,
        cancel: generateCancelButton(key[0])
      });
      };
    }

    return data;
  };


  const cancelHoldings = async (pair: string): Promise<void> => {

    let loading = function () {
      return undefined;
    };

    try {
      tezos.setWalletProvider(initialState.wallet);
      const contractWallet = await tezos.wallet.at(contractAddress);
      let methods = contractWallet.parameterSchema.ExtractSignatures();
      console.info("Methods", methods);

      const holding = openHoldings.get(pair);
      console.info("Holding", holding);

      let cancel_op = await contractWallet.methodsObject.cancel([holding.buy_token_name, holding.sell_token_name]).send();


      if (cancel_op) {
        loading = message.loading('Attempting to cancel open holdings...', 0);
        const confirm = await cancel_op.confirmation();
        if (!confirm.completed) {
          message.error('Failed to cancel open holdings');
          console.error('Failed to cancel open holdings' + confirm);
        } else {
          setOpenHoldings(new Map<string, holding>());
          loading();
          message.success('Successfully cancelled open holdings');
          triggerUpdate();
        }
      } else {
        throw new Error('Failed to cancel open holdings');
      }
    } catch (error: any) {
      loading();
      message.error('Unable to redeem holdings : ' + error.message);
      console.error('Unable to redeem holdings' + error);
  };
  };


  const redeemHoldings = async (): Promise<void> => {
    let loading = function () {
      return undefined;
    };

    try {
      tezos.setWalletProvider(initialState.wallet);
      const contractWallet = await tezos.wallet.at(contractAddress);
      let redeem_op = await contractWallet.methods.redeem().send();

      if (redeem_op) {
        loading = message.loading('Attempting to redeem holdings...', 0);
        const confirm = await redeem_op.confirmation();
        if (!confirm.completed) {
          message.error('Failed to redeem holdings');
          console.error('Failed to redeem holdings' + confirm);
        } else {
          setOpenHoldings(new Map<string, number>());
          setClearedHoldings(new Map<string, number>());
          loading();
          message.success('Successfully redeemed holdings');
          triggerUpdate();
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
        <Typography className="batcher-title p-16">Open Batches (Cancellable)</Typography>
        { hasOpenHoldings ?
        (
        <Col className="batcher-holding-content br-t br-b br-l br-r pd-25 tx-align" span={24}>
          <Space direction="horizontal">
              <Table
                className="batcher-table ant-typeography center"
                columns={listOfColumnsWithCancel}
                rowKey="pair"
                dataSource={generateOpenHoldings(openHoldings)}
                pagination={false}
              />
          </Space>
        </Col>
        ) : (
        <Col className="batcher-holding-content br-t br-b br-l br-r pd-25 tx-align" span={24}>
            <Typography> No closed holdings </Typography>
          </Col>
        )}
      </Space>
      <Space className="batcher-price" direction="vertical">
        <Typography className="batcher-title p-16">Closed Batches</Typography>
        { hasClosedHoldings ?
        (<Col className="batcher-holding-content br-t br-b br-l br-r pd-25 tx-align" span={24}>
          <Space direction="horizontal">
              <Table
                className="batcher-table ant-typeography center"
                columns={listOfColumns}
                rowKey="pair"
                dataSource={generateHoldings(closedHoldings)}
                pagination={false}
              />
          </Space>
        </Col> ) :

        (
        <Col className="batcher-holding-content br-t br-b br-l br-r pd-25 tx-align" span={24}>
            <Typography> No closed holdings </Typography>
          </Col>
          )
        }
      </Space>
      <Space className="batcher-price" direction="vertical">
        <Typography className="batcher-title p-16">Cleared Batches (Redeemable)</Typography>
          { hasClearedHoldings ?
          ( <Col className="batcher-holding-content br-t br-b br-l br-r pd-25 tx-align" span={24}>
          <Space direction="horizontal">
              <Table
                className="batcher-table ant-typeography center"
                columns={listOfColumns}
                rowKey="pair"
                dataSource={generateHoldings(clearedHoldings)}
                pagination={false}
              />
          </Space>
      <Space className="batcher-price" direction="vertical">
        <Col className="batcher-redeem-btn">
            <Button className="btn-content mtb-25" type="primary" onClick={redeemHoldings} danger>
              Redeem
            </Button>
        </Col>
      </Space>
             </Col>
 ) :
          (
          <Col className="batcher-holding-content br-t br-b br-l br-r pd-25 tx-align" span={24}>
            <Typography> No cleared holdings </Typography>
          </Col>
      )
      }
      </Space>
    </Col>
  );
};

export default Holdings;
