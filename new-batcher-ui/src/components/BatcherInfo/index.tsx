import React, { useEffect, useState } from 'react';
import { SwapOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row } from 'antd';
import { useModel } from 'umi';
import '@/components/Exchange/index.less';
import '@/global.less';
import { ExchangeProps } from '@/extra_utils/types';
import { getTokenAmount } from '@/extra_utils/utils';

const { Text } = Typography;

const BatcherInfo: React.FC<ExchangeProps> = ({ buyToken, sellToken }: ExchangeProps) => {
  const [inversion, setInversion] = useState(true);
  const [buyBalance, setBuyBalance] = useState({
    name: 'tzBTC',
    address: buyToken.address,
    decimal: buyToken.decimal,
    balance: 0,
  });
  const [sellBalance, setSellBalance] = useState({
    name: 'USDT',
    address: sellToken.address,
    decimal: sellToken.decimal,
    balance: 0,
  });

  const { initialState } = useModel('@@initialState');
  const { wallet, userAddress } = initialState;

  const getTokenBalance = async () => {
    if (userAddress) {
      const balanceURI =
        'https://api.kathmandunet.tzkt.io/v1/tokens/balances?account=' + userAddress;
      const data = await fetch(balanceURI, { method: 'GET' });
      const balance = await data.json();
      if (Array.isArray(balance)) {
        const baseAmount = getTokenAmount(balance, buyBalance);
        const quoteAmount = getTokenAmount(balance, sellBalance);
        setBuyBalance({ ...buyBalance, balance: buyAmount });
        setSellBalance({ ...sellBalance, balance: sellAmount });
      }
    } else {
      setBuyBalance({
        name: 'tzBTC',
        address: buyToken.address,
        decimal: buyToken.decimal,
        balance: 0,
      });
      setSellBalance({
        name: 'USDT',
        address: sellToken.address,
        decimal: sellToken.decimal,
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
            <Space className="pd-0">
              <Typography className="batcher-title p-16">Balance</Typography>
              <Typography className="batcher-title p-13">
                {inversion
                  ? buyBalance.balance + ' ' + buyBalance.name
                  : sellBalance.balance + ' ' + sellBalance.name}
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
