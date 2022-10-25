import React, { useEffect, useState } from 'react';
import { SwapOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row, message, Form } from 'antd';
import { useModel } from 'umi';
import '@/components/Exchange/index.less';
import '@/global.less';
import { ExchangeProps, ToleranceType } from '@/extra_utils/types';
import { getErrorMess, scaleAmountUp } from '@/extra_utils/utils';
import { TezosToolkit } from '@taquito/taquito';
import useFormInstance from 'antd/lib/form/hooks/useFormInstance';

const Tezos = new TezosToolkit(REACT_APP_TEZOS_NODE_URI);

const Exchange: React.FC<ExchangeProps> = ({
  buyBalance,
  sellBalance,
  inversion,
  setInversion,
}: ExchangeProps) => {
  const [tolerance, setTolerance] = useState(ToleranceType.EXACT);
  const [amount, setAmount] = useState(0);
  const { initialState } = useModel('@@initialState');
  const { wallet, userAddress } = initialState;

  const [form] = Form.useForm();

  const inverseTokenType = () => {
    setInversion(!inversion);
  };
  const depositToken = async () => {
    if (!wallet) {
      return;
    }

    const batcherContract = await Tezos.wallet.at(REACT_APP_BATCHER_CONTRACT_HASH);
    const tokenContract = await Tezos.wallet.at(
      inversion ? buyBalance.token.address : sellBalance.token.address,
    );

    console.log('%cindex.tsx line:37 amount', 'color: #007acc;', amount);

    const scaled_amount = inversion
      ? scaleAmountUp(amount, buyBalance.token.decimals)
      : scaleAmountUp(amount, sellBalance.token.decimals);

    const operator_params = [
      {
        add_operator: {
          owner: userAddress,
          operator: REACT_APP_BATCHER_CONTRACT_HASH,
          token_id: 0,
        },
      },
    ];

    const swap_params = {
      trader: userAddress,
      swap: {
        from: {
          token: {
            name: inversion ? buyBalance.token.name : sellBalance.token.name,
            address: inversion ? buyBalance.token.address : sellBalance.token.address,
            decimals: inversion ? buyBalance.token.decimals : sellBalance.token.decimals,
          },
          amount: scaled_amount,
        },
        to: {
          name: inversion ? sellBalance.token.name : buyBalance.token.name,
          address: inversion ? sellBalance.token.address : buyBalance.token.address,
          decimals: inversion ? sellBalance.token.decimals : buyBalance.token.decimals,
        },
      },
      created_at: new Date(),
      side: inversion ? 0 : 1,
      tolerance: tolerance,
    };

    const loading = message.loading(
      'Attempting to place swap order for ' +
        (inversion ? buyBalance.token.name : sellBalance.token.name),
      0,
    );

    try {
      Tezos.setWalletProvider(wallet);
      const order_batcher_op = await Tezos.wallet
        .batch()
        .withContractCall(tokenContract.methods.update_operators(operator_params))
        .withContractCall(batcherContract.methodsObject.deposit(swap_params))
        .send();
      const confirm = await order_batcher_op.confirmation();
      if (!confirm.completed) {
        throw new Error(
          'Failed to deposit ' +
            (inversion ? buyBalance.token.name : sellBalance.token.name) +
            ' token',
        );
      } else {
        loading();
        form.resetFields();
        message.success(
          'Successfully deposit ' +
            (inversion ? buyBalance.token.name : sellBalance.token.name) +
            ' token',
        );
      }
    } catch (error) {
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
        {wallet ? (
          <Form.Item>
            <div className="tx-align">
              <Button className="mtb-25" type="primary" htmlType="submit" danger>
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
