import React, { useState, useEffect } from 'react';
import {  SwapOutlined, SettingOutlined, RetweetOutlined, DollarOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row, message, Form, Drawer, Radio, } from 'antd';
import {  compose, OpKind,  WalletContract, } from "@taquito/taquito";
import { useModel } from 'umi';
import '@/components/Exchange/index.less';
import '@/global.less';
import { ExchangeProps, PriceType, } from '@/extra_utils/types';
// import { ReactComponent as ExchangeDollarSvg } from '../../../img/exchange-dollar.svg';
import { getErrorMess, scaleAmountUp } from '@/extra_utils/utils';
import { tzip12, Tzip12Module } from "@taquito/tzip12";
import { tzip16 } from "@taquito/tzip16";

const Exchange: React.FC<ExchangeProps> = ({
  userAddress,
  buyBalance,
  sellBalance,
  inversion,
  setInversion,
  tezos,
  fee_in_mutez,
  buyToken,
  sellToken,
  showDrawer,
  updateAll,
  setUpdateAll
}: ExchangeProps) => {

// const DollarIcon = (props: Partial<CustomIconComponentProps>) => (
//  <Icon component={ExchangeDollarSvg} {...props} />
// );



  const [price, setPrice] = useState(PriceType.EXACT);
  const [side, setSide] = useState(0);
  const [amount, setAmount] = useState(0);
  const { initialState } = useModel('@@initialState');

  const [form] = Form.useForm();

  tezos.addExtension(new Tzip12Module());

  const triggerUpdate = () => {
    const u = !updateAll;
    setUpdateAll(u);

  };


  const inverseTokenType = () => {
    setInversion(!inversion);
    const s = inversion ? 0 : 1;
    setSide(s);
  };


  const depositToken = async () => {
    if (!userAddress) {
      return;
    }

    const tokenName = inversion ? buyToken.name : sellToken.name;
    const selectedToken = inversion ? buyToken : sellToken;
    const batcherContract = await tezos.wallet.at(REACT_APP_BATCHER_CONTRACT_HASH);
    const tokenContract : WalletContract = await tezos.wallet.at(
      inversion ? buyToken.address : sellToken.address, compose(tzip12,tzip16));


    const scaled_amount = inversion
      ? scaleAmountUp(amount, buyToken.decimals)
      : scaleAmountUp(amount, sellToken.decimals);

    const selected_side = inversion ? 0 : 1;
    let tolerance = 0;

    if(selected_side == 0) {
      if (price === PriceType.WORSE) {
        tolerance = 0;
      } else if (price === PriceType.EXACT) {
        tolerance = 1;
      } else {
        tolerance = 2;
      }
    } else {
      if (price === PriceType.WORSE) {
        tolerance = 2;
      } else if (price === PriceType.EXACT) {
        tolerance = 1;
      } else {
        tolerance = 0;
     }
    }
     


    // This is for fa2 token standard. I.e, USDT token
    const fa2_add_operator_params = [
      {
        add_operator: {
          owner: userAddress,
          operator: REACT_APP_BATCHER_CONTRACT_HASH,
          token_id: 0,
        },
      },
    ];

    const fa2_remove_operator_params = [
      {
        remove_operator: {
          owner: userAddress,
          operator: REACT_APP_BATCHER_CONTRACT_HASH,
          token_id: 0,
        },
      },
    ];


    let loading = function () {
      return undefined;
    };

    try {
      let order_batcher_op = null;

      console.log('operations-token', selectedToken);
      console.log('operations-side', side);
      console.log('operations-fee-in-mutez', fee_in_mutez);

      const swap_params = {
        swap: {
          from: {
            token: {
              name: inversion ? buyToken.name : sellToken.name,
              address: inversion ? buyToken.address : sellToken.address,
              decimals: inversion ? buyToken.decimals : sellToken.decimals,
              standard: inversion ? buyToken.standard : sellToken.standard,
            },
            amount: scaled_amount,
          },
          to: {
            name: inversion ? sellToken.name : buyToken.name,
            address: inversion ? sellToken.address : buyToken.address,
            decimals: inversion ? sellToken.decimals : buyToken.decimals,
            standard: inversion ? sellToken.standard : buyToken.standard,
          },
        },
        created_at: new Date(),
        side: selected_side,
        tolerance: tolerance,
       };

       console.log("test");

      if (selectedToken.standard === 'FA1.2 token') {
        console.log("inversion", inversion);
        console.log("buy", buyToken);
        console.log("sell", sellToken);
        const tokenfa12Contract : WalletContract = await tezos.wallet.at(buyToken.address, compose(tzip12,tzip16));
        console.log("methods", tokenfa12Contract.methods);
        order_batcher_op = await tezos.wallet
          .batch([
          {
            kind: OpKind.TRANSACTION,
            ...tokenfa12Contract.methods.approve(REACT_APP_BATCHER_CONTRACT_HASH, scaled_amount).toTransferParams(),
          },
          {
            kind: OpKind.TRANSACTION,
            ...batcherContract.methodsObject.deposit(swap_params).toTransferParams(),
            to: REACT_APP_BATCHER_CONTRACT_HASH,
            amount: fee_in_mutez,
            mutez: true,
          }
          ])
          .send();
      }

      if (selectedToken.standard === 'FA2 token') {
        order_batcher_op = await tezos.wallet
          .batch([
          {
            kind: OpKind.TRANSACTION,
            ...tokenContract.methods.update_operators(fa2_add_operator_params).toTransferParams()
          },
          {
            kind: OpKind.TRANSACTION,
            ...batcherContract.methodsObject.deposit(swap_params).toTransferParams(),
            to: REACT_APP_BATCHER_CONTRACT_HASH,
            amount: fee_in_mutez,
            mutez: true,
          },
          {
            kind: OpKind.TRANSACTION,
            ...tokenContract.methods.update_operators(fa2_remove_operator_params).toTransferParams()
          }
          ])
          .send();
      }

      loading = message.loading('Attempting to place swap order for ' + tokenName, 0);
      const confirm = await order_batcher_op.confirmation();
      if (!confirm.completed) {
        console.error(confirm);
        message.error('Failed to deposit ' + tokenName);
        throw new Error(
          'Failed to deposit ' +
            (inversion ? buyToken.name : sellToken.name) +
            ' token',
        );
      } else {
        loading();
        form.resetFields();
        message.success('Successfully deposited ' + tokenName);
        triggerUpdate();
      }
    } catch (error) {
      console.log('deposit error', error);
      const converted_error_message = getErrorMess(error);
      message.error(converted_error_message);
      loading();
      form.resetFields();
    }
  };

  return (
    <div>
      <Form onFinish={depositToken} form={form}>
        <Col className="base-content br-t br-b br-l br-r">
          <Space className="batcher-price" direction="vertical">
            <Form.Item
              className="batcher-amount mb-0"
              label={
                <Typography className="batcher-title p-16">
                  From {inversion ? buyToken.name : sellToken.name}
                </Typography>
              }
              name="amount"
              rules={[
                { required: true, message: 'Please input your amount' },
                { pattern: new RegExp(/^[+-]?([0-9]*[.])?[0-9]+$/), message: 'Invalid number' },
                () => ({
                  validator(_, value) {
                    if (inversion && Number.parseFloat(value) > buyBalance) {
                      return Promise.reject('Greater than the balance');
                    } else if (!inversion && Number.parseFloat(value) > sellBalance) {
                      return Promise.reject('Greater than the balance');
                    }
                    return Promise.resolve();
                  },
                }),
              ]}
            >
              <Input
                className="batcher-token"
                placeholder="Amount"
                disabled={!userAddress}
                onChange={(e) => {
                  const regrex = /^[+-]?([0-9]*[.])?[0-9]+$/;
                  if (regrex.test(e.target.value)) {
                    setAmount(Number.parseFloat(e.target.value));
                  }
                }}
              />
            </Form.Item>
            <Typography className="batcher-title p-13">
              Select the price you want to sell
            </Typography>
            <Row className="text-center">
              <Col
                className={
                  price === PriceType.WORSE
                    ? 'batcher-title batcher-col-focus pd-5 br-t br-b br-l br-r'
                    : 'batcher-title pd-5 br-t br-b br-l br-r'
                }
                span={8}
                onClick={() => setPrice(PriceType.WORSE)}
              >
                <Typography className="p-12">Worse price / Better fill</Typography>
              </Col>
              <Col
                className={
                  price === PriceType.EXACT
                    ? 'batcher-title batcher-col-focus pd-5 br-t br-b br-r'
                    : 'batcher-title pd-5 br-t br-b br-r'
                }
                span={8}
                onClick={() => setPrice(PriceType.EXACT)}
              >
                <Typography className="p-12">Oracle Price</Typography>
              </Col>
              <Col
                className={
                  price === PriceType.BETTER
                    ? 'batcher-title batcher-col-focus pd-5 br-t br-b br-r'
                    : 'batcher-title pd-5 br-t br-b br-r'
                }
                span={8}
                onClick={() => setPrice(PriceType.BETTER)}
              >
                <Typography className="p-12">Better Price / Worse Fill</Typography>
              </Col>
            </Row>
          </Space>
        </Col>
        <Col className="batcher-action-items" lg={24} xs={24}>
        <Space align="center" size={100}>
        <SwapOutlined
          className="exchange-button grid-padding"
          onClick={inverseTokenType}
          rotate={90}
        />
        <div onClick={showDrawer}>
        <SettingOutlined
          className="exchange-button"
        />
        </div>
        </Space>
        </Col>
        <Col className="quote-content grid-padding br-t br-b br-l br-r">
          <Typography className="batcher-title p-16">
            To {inversion ? sellToken.name : buyToken.name}
          </Typography>
        </Col>
        {userAddress ? (
          <Form.Item>
            <div className="tx-align">
              <Button className="swap-btn mtb-25" type="primary" htmlType="submit" danger>
                Try to swap
              </Button>
            </div>
          </Form.Item>
        ) : (
          <div></div>
        )}
      </Form>
    </div>
  );
};

export default Exchange;
