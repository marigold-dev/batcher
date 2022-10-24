import React, { useEffect, useState } from 'react';
import { SwapOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row } from 'antd';
import { useModel } from 'umi';
import '@/components/Exchange/index.less';
import '@/global.less';
import { BatcherInfoProps, ExchangeProps } from '@/extra_utils/types';
import { getTokenAmount } from '@/extra_utils/utils';

const { Text } = Typography;

const BatcherInfo: React.FC<BatcherInfoProps> = ({
  baseToken,
  quoteToken,
  inversion,
}: BatcherInfoProps) => {
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

  const getTokenBalance = async () => {
    if (userAddress) {
      const balanceURI = REACT_APP_TZKT_URI_API + '/v1/tokens/balances?account=' + userAddress;
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
            <Typography className="batcher-title p-13">No open Batch</Typography>
          </Space>
        </Col>
        <Col className="batcher-balance" xs={24} lg={6}>
          <Col className="batcher-balance-title" span={24}>
            <Space className="pd-0">
              <Typography className="batcher-title p-16">Balance</Typography>
              <Typography className="batcher-title p-13">
                {inversion
                  ? baseBalance.balance + ' ' + baseBalance.name
                  : quoteBalance.balance + ' ' + quoteBalance.name}
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
    </div>
  );
};

export default BatcherInfo;
