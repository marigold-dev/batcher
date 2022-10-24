import React, { useEffect, useState } from 'react';
import { SwapOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row } from 'antd';
import { useModel } from 'umi';
import '@/components/Exchange/index.less';
import '@/global.less';
import { ExchangeProps } from '@/extra_utils/types';
import { getTokenAmount } from '@/extra_utils/utils';

const { Text } = Typography;

const Exchange: React.FC<ExchangeProps> = ({ buyToken, sellToken }: ExchangeProps) => {
  const [inversion, setInversion] = useState(true);
  const [buyBalance, setBuyBalance] = useState({
    token: buyToken,
    balance: 0,
  });
  const [sellBalance, setSellBalance] = useState({
    token: sellToken,
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
        const baseAmount = getTokenAmount(balance, buyBalance);
        const quoteAmount = getTokenAmount(balance, sellBalance);
        setBuyBalance({ ...buyBalance, balance: baseAmount });
        setSellBalance({ ...sellBalance, balance: quoteAmount });
      }
    } else {
      setBuyBalance({
        token: buyToken,
        balance: 0,
      });
      setSellBalance({
        token: sellToken,
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
              <Col className="base-content br-t br-b br-l br-r">
                <Space className="batcher-price" direction="vertical">
                  <Row>
                    <Col className="mr-c" span={5}>
                      <Typography className="batcher-title p-16">
                        From {inversion ? buyBalance.token.name : sellBalance.token.name}
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
                  To {inversion ? sellBalance.token.name : buyBalance.token.name}
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
    </div>
  );
};

export default Exchange;
