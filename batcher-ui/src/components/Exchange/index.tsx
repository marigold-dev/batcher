import React, { useState } from 'react';
import { SwapOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row, message, Form } from 'antd';
import { BigMapAbstraction, compose, OpKind, TezosToolkit, WalletContract, WalletOperationBatch, WalletParamsWithKind } from "@taquito/taquito";
import { useModel } from 'umi';
import '@/components/Exchange/index.less';
import '@/global.less';
import { ExchangeProps, ToleranceType, SideType } from '@/extra_utils/types';
import { getErrorMess, scaleAmountUp } from '@/extra_utils/utils';
import { TokenMetadata, tzip12, Tzip12Module, Tzip12ContractAbstraction } from "@taquito/tzip12";
import { tzip16 } from "@taquito/tzip16";
import BigNumber from 'bignumber.js';

const Exchange: React.FC<ExchangeProps> = ({
  buyBalance,
  sellBalance,
  inversion,
  setInversion,
  tezos,
  fee_in_mutez,
}: ExchangeProps) => {
  const [tolerance, setTolerance] = useState(ToleranceType.EXACT);
  const [side, setSide] = useState(SideType.BUY);
  const [amount, setAmount] = useState(0);
  const { initialState } = useModel('@@initialState');
  const { userAddress } = initialState;

  const [form] = Form.useForm();

  tezos.addExtension(new Tzip12Module());

  const inverseTokenType = () => {
    setInversion(!inversion);
    const s = inversion ? 0 : 1;
    setSide(s);
  };
  const depositToken = async () => {
    if (!userAddress) {
      return;
    }

    const tokenName = inversion ? buyBalance.token.name : sellBalance.token.name;
    const selectedToken = inversion ? buyBalance.token : sellBalance.token;
    const batcherContract = await tezos.wallet.at(REACT_APP_BATCHER_CONTRACT_HASH);
    const tokenContract : WalletContract = await tezos.wallet.at(
      inversion ? buyBalance.token.address : sellBalance.token.address, compose(tzip12,tzip16));


    const scaled_amount = inversion
      ? scaleAmountUp(amount, buyBalance.token.decimals)
      : scaleAmountUp(amount, sellBalance.token.decimals);

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

    // This is for fa1.2 token standard. I.e, tzBTC token
    const fa12_operation_params = {
      spender: REACT_APP_BATCHER_CONTRACT_HASH,
      value: scaled_amount,
    };




    let loading = function () {
      return undefined;
    };

    try {
      let order_batcher_op = null;
      const operations: WalletParamsWithKind[] = [];

      console.log('operations-empty', operations);
      let decimals = Math.pow(10, 6);
      let orig = new BigNumber(0)
      let amt = orig.multipliedBy(decimals);

      if (selectedToken.standard === 'FA1.2 token') {
      let faDecimals = Math.pow(10,(await tokenContract.tzip12().getTokenMetadata(0)).decimals);
        operations.push({
          kind: OpKind.TRANSACTION,
          ...tokenContract.methods.approve(REACT_APP_BATCHER_CONTRACT_HASH,amt).toTransferParams(),
        });
     console.log('operations-fa1.2-approve', operations);
     }



      if (selectedToken.standard === 'FA2 token') {
         operations.push({
           kind: OpKind.TRANSACTION,
           ...tokenContract.methods.update_operators(fa2_add_operator_params).toTransferParams(),
         });
      console.log('operations-fa2-update_operators', operations);
      }

      operations.push({
          kind: OpKind.TRANSACTION,
          ...batcherContract.methods.deposit([{
                                              swap: {
                                                from: {
                                                  token: {
                                                    name: inversion ? buyBalance.token.name : sellBalance.token.name,
                                                    address: inversion ? buyBalance.token.address : sellBalance.token.address,
                                                    decimals: inversion ? buyBalance.token.decimals : sellBalance.token.decimals,
                                                    standard: inversion ? buyBalance.token.standard : sellBalance.token.standard,
                                                  },
                                                  amount: scaled_amount,
                                                },
                                                to: {
                                                  name: inversion ? sellBalance.token.name : buyBalance.token.name,
                                                  address: inversion ? sellBalance.token.address : buyBalance.token.address,
                                                  decimals: inversion ? sellBalance.token.decimals : buyBalance.token.decimals,
                                                  standard: inversion ? sellBalance.token.standard : buyBalance.token.standard,
                                                },
                                              },
                                              created_at: new Date(),
                                              side: side,
                                              tolerance: tolerance,
                                             }]).toTransferParams(),
      });


      console.log('operations-deposit', operations);

      if (selectedToken.standard === 'FA2 token') {
         operations.push({
           kind: OpKind.TRANSACTION,
           ...tokenContract.methods.update_operators(fa2_remove_operator_params).toTransferParams(),
         });

      console.log('operations-remove_ops', operations);
      }

      loading = message.loading('Attempting to place swap order for ' + tokenName, 0);

      console.log('operations', operations);
      order_batcher_op = await tezos.wallet.batch(operations).send();
      const confirm = await order_batcher_op.confirmation();
      if (!confirm.completed) {
        message.error('Failed to deposit ' + tokenName);
        throw new Error(
          'Failed to deposit ' +
            (inversion ? buyBalance.token.name : sellBalance.token.name) +
            ' token',
        );
      } else {
        loading();
        form.resetFields();
        message.success('Successfully deposited ' + tokenName);
      }
    } catch (error) {
      console.log('deposit error', error);
      loading();
      form.resetFields();
      message.error(getErrorMess(error));
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
                  From {inversion ? buyBalance.token.name : sellBalance.token.name}
                </Typography>
              }
              name="amount"
              rules={[
                { required: true, message: 'Please input your amount' },
                { pattern: new RegExp(/^[+-]?([0-9]*[.])?[0-9]+$/), message: 'Invalid number' },
                () => ({
                  validator(_, value) {
                    if (inversion && Number.parseFloat(value) > buyBalance.balance) {
                      return Promise.reject('Greater than the balance');
                    } else if (!inversion && Number.parseFloat(value) > sellBalance.balance) {
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
                  tolerance === ToleranceType.MINUS
                    ? 'batcher-title batcher-col-focus pd-5 br-t br-b br-l br-r'
                    : 'batcher-title pd-5 br-t br-b br-l br-r'
                }
                span={8}
                onClick={() => setTolerance(ToleranceType.MINUS)}
              >
                <Typography className="p-12">Worse price / Better fill</Typography>
              </Col>
              <Col
                className={
                  tolerance === ToleranceType.EXACT
                    ? 'batcher-title batcher-col-focus pd-5 br-t br-b br-r'
                    : 'batcher-title pd-5 br-t br-b br-r'
                }
                span={8}
                onClick={() => setTolerance(ToleranceType.EXACT)}
              >
                <Typography className="p-12">Oracle Price</Typography>
              </Col>
              <Col
                className={
                  tolerance === ToleranceType.PLUS
                    ? 'batcher-title batcher-col-focus pd-5 br-t br-b br-r'
                    : 'batcher-title pd-5 br-t br-b br-r'
                }
                span={8}
                onClick={() => setTolerance(ToleranceType.PLUS)}
              >
                <Typography className="p-12">Better Price / Worse Fill</Typography>
              </Col>
            </Row>
          </Space>
        </Col>
        <SwapOutlined
          className="exchange-button grid-padding"
          onClick={inverseTokenType}
          rotate={90}
        />
        <Col className="quote-content grid-padding br-t br-b br-l br-r">
          <Typography className="batcher-title p-16">
            To {inversion ? sellBalance.token.name : buyBalance.token.name}
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
