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
  const [inversion, setInversion] = useState(true);
  const [baseBalance, setBaseBalance] = useState({
    name: 'tzBTC',
    address: baseToken.address,
    decimal: baseToken.decimal,
    balance: 0,
  });
  const [quoteBalance, setQuoteBalance] = useState({
    name: 'USDT',
    address: quoteToken.address,
    decimal: quoteToken.decimal,
    balance: 0,
  });

  const { initialState } = useModel('@@initialState');
  const { wallet, userAddress } = initialState;

  const inverseTokenType = () => {
    setInversion(!inversion);
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
    } else {
      setBaseBalance({
        name: 'tzBTC',
        address: baseToken.address,
        decimal: baseToken.decimal,
        balance: 0,
      });
      setQuoteBalance({
        name: 'USDT',
        address: quoteToken.address,
        decimal: quoteToken.decimal,
        balance: 0,
      });
      setInversion(true);
    }
  };

  useEffect(() => {
    const exchangeInterval = setInterval(getTokenBalance, 2000);
    return () => clearInterval(exchangeInterval);
  }, [initialState]);

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
                <Typography className="batcher-title p-16">
                  To {inversion ? quoteBalance.name : baseBalance.name}
                </Typography>
              </Col>
              {wallet ? (
                <div className="tx-align">
                  <Button className="mtb-25" type="primary" danger>
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
