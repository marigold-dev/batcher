import React, { useEffect, useState } from 'react';
import { SwapOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row } from 'antd';
import { useModel } from 'umi';
import '@/components/Exchange/index.less';
import '@/global.less';
import { ExchangeProps } from '@/extra_utils/types';
import { getTokenAmount } from '@/extra_utils/utils';

const { Text } = Typography;

const Exchange: React.FC<ExchangeProps> = ({ baseToken, quoteToken }: ExchangeProps) => {
  const [baseBalance, setBaseBalance] = useState({
    name: 'tzBTC',
    address: baseToken.address,
    decimal: baseToken.decimal,
    balance: null,
  });
  const [quoteBalance, setQuoteBalance] = useState({
    name: 'USDT',
    address: quoteToken.address,
    decimal: quoteToken.decimal,
    balance: null,
  });

  const { initialState } = useModel('@@initialState');
  console.log('%cindex.tsx line:18 initialState', 'color: #007acc;-------', baseBalance);
  const { wallet, userAddress } = initialState;

  const inverseTokenType = () => {
    const originalBaseBalance = baseBalance;
    const originalQuoteBalance = quoteBalance;
    setBaseBalance(originalQuoteBalance);
    setQuoteBalance(originalBaseBalance);
  };

  const getTokenBalance = async () => {
    if (userAddress) {
      const balanceURI =
        'https://api.kathmandunet.tzkt.io/v1/tokens/balances?account=' + userAddress;
      const data = await fetch(balanceURI, { method: 'GET' });
      const balance = await data.json();
      if (Array.isArray(balance)) {
        const baseAmount = getTokenAmount(balance, baseBalance);
        const quoteAmount = getTokenAmount(balance, quoteBalance);
        setBaseBalance({ ...baseBalance, balance: baseAmount });
        setQuoteBalance({ ...quoteBalance, balance: quoteAmount });
      }
      console.log(balance);
    }
  };

  useEffect(() => {
    const exchangeInterval = setInterval(getTokenBalance, 2000);
    return () => clearInterval(exchangeInterval);
  }, [initialState]);

  return (
    <div>
      <Row className="batcher-header">
        <Col lg={3} />
        <Col className="batcher-time" xs={24} lg={6}>
          <Space direction="vertical">
            <Typography className="batcher-title p-16">Batcher Time Remaining</Typography>
            <Typography className="batcher-title p-13">Open Batch</Typography>
          </Space>
        </Col>
        <Col className="batcher-balance" xs={24} lg={6}>
          <Col className="batcher-balance-title" span={24}>
            <Space>
              <Typography className="batcher-title p-16">Balance</Typography>
              <Typography className="batcher-title p-13">
                {baseBalance.balance + ' ' + baseBalance.name}
              </Typography>
            </Space>
          </Col>
          <Col className="batcher-balance-amount" span={24}>
            <Space className="pd-0">
              <Typography>Address</Typography>
              {userAddress ? (
                <Text style={{ width: 150 }} ellipsis={{ tooltip: userAddress }}>
                  {userAddress}
                </Text>
              ) : (
                <Text className="batcher-title p-13">No Wallet connected</Text>
              )}
            </Space>
          </Col>
        </Col>
        <Col className="batcher-oracle" xs={24} lg={6}>
          <Space>
            <Typography className="batcher-title p-16">Oracle Price</Typography>
            <Typography className="batcher-title p-13">0 tzBTC/USDT</Typography>
          </Space>
        </Col>
        <Col lg={3} />
      </Row>
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
                        From {baseBalance.name}
                      </Typography>
                    </Col>
                    <Col span={14}>
                      <Input className="batcher-token" placeholder="Amount" />
                    </Col>
                  </Row>
                  <Typography className="batcher-title p-13">
                    Select the price you want to sell
                  </Typography>
                  <Row className="text-center">
                    <Col className="batcher-title pd-5 br-t br-l br-b" span={8}>
                      <Typography className="p-12">Worse price / Better fill</Typography>
                    </Col>
                    <Col className="batcher-title pd-5 br-t br-b br-l br-r" span={8}>
                      <Typography className="p-12">Oracle Price</Typography>
                    </Col>
                    <Col className="batcher-title pd-5 br-t br-b br-r" span={8}>
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
                <Typography className="batcher-title p-16">To {quoteBalance.name}</Typography>
              </Col>
              <div className="tx-align">
                <Button className="mtb-25" type="primary" danger>
                  Try to swap
                </Button>
              </div>
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
