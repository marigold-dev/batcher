import React, { useState } from 'react';
import { SwapOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row, message } from 'antd';
import { useModel } from 'umi';
import '@/components/Exchange/index.less';
import '@/global.less';
import { ExchangeProps, ToleranceType } from '@/extra_utils/types';
import { getErrorMess, rationaliseAmount } from '@/extra_utils/utils';
import { TezosToolkit } from '@taquito/taquito';

const Tezos = new TezosToolkit(REACT_APP_TEZOS_NODE_URI);

const Exchange: React.FC<ExchangeProps> = ({
  baseBalance,
  quoteBalance,
  inversion,
  setInversion,
}: ExchangeProps) => {
  const [tolerance, setTolerance] = useState(ToleranceType.MINUS);
  const [amount, setAmount] = useState(0);

  const { initialState } = useModel('@@initialState');
  const { wallet, userAddress } = initialState;

  const inverseTokenType = () => {
    setInversion(!inversion);
  };

  const depositToken = async () => {
    if (!wallet) {
      return;
    }

    const batcherContract = await Tezos.wallet.at(REACT_APP_BATCHER_CONTRACT_HASH);
    const tokenContract = await Tezos.wallet.at(
      inversion ? baseBalance.address : quoteBalance.address,
    );

    const scaled_amount = inversion
      ? rationaliseAmount(amount, baseBalance.decimal)
      : rationaliseAmount(amount, quoteBalance.decimal);

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
            name: inversion ? baseBalance.name : quoteBalance.name,
            address: inversion ? baseBalance.address : quoteBalance.address,
            decimals: inversion ? baseBalance.decimal : quoteBalance.decimal,
          },
          amount: scaled_amount,
        },
        to: {
          name: inversion ? quoteBalance.name : baseBalance.name,
          address: inversion ? quoteBalance.address : baseBalance.address,
          decimals: inversion ? quoteBalance.decimal : baseBalance.decimal,
        },
      },
      created_at: new Date(),
      side: inversion ? 0 : 1,
      tolerance: tolerance,
    };

    const loading = message.loading(
      'Attempting to place swap order for ' + (inversion ? baseBalance.name : quoteBalance.name),
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
          'Failed to deposit ' + (inversion ? baseBalance.name : quoteBalance.name) + ' token',
        );
      } else {
        loading();
        message.success(
          'Successfully deposit ' + (inversion ? baseBalance.name : quoteBalance.name) + ' token',
        );
      }
    } catch (error) {
      loading();
      message.error(getErrorMess(error));
    }
  };

  return (
    <div>
      <Row className="batcher-content">
        <Col lg={3} />
        <Col className="batcher-content-outer" xs={24} lg={18}>
          <Row>
            <Col lg={3} />
            <Col xs={24} lg={18} className="pd-25">
              <Col className="base-content br-t br-b br-l br-r">
                <Space className="batcher-price" direction="vertical">
                  <Row>
                    <Col className="mr-c" span={5}>
                      <Typography className="batcher-title p-16">
                        From {inversion ? baseBalance.name : quoteBalance.name}
                      </Typography>
                    </Col>
                    <Col span={14}>
                      <Input
                        className="batcher-token"
                        placeholder="Amount"
                        onChange={(e) => {
                          setAmount(Number.parseInt(e.target.value));
                        }}
                      />
                    </Col>
                  </Row>
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
                  To {inversion ? quoteBalance.name : baseBalance.name}
                </Typography>
              </Col>
              {wallet ? (
                <div className="tx-align">
                  <Button className="mtb-25" type="primary" onClick={depositToken} danger>
                    Try to swap
                  </Button>
                </div>
              ) : (
                <div></div>
              )}
            </Col>
            <Col lg={3} />
          </Row>
        </Col>
        <Col lg={3} />
      </Row>
    </div>
  );
};

export default Exchange;
