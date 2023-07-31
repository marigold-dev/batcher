import React, { useState } from 'react';
import { Space, Typography, Col, Row, Table } from 'antd';
// import '../Exchange/index.less';
// import './index.less';
// import '../../src/global.less';
import { VolumeProps } from '../../utils/types';

const Volume: React.FC<VolumeProps> = ({ volumes }: VolumeProps) => {
  console.log(555, volumes);

  const sellVolumes = [
    {
      sellMinusVolume: volumes.sell_minus_volume,
      sellExactVolume: volumes.sell_exact_volume,
      sellPlusVolume: volumes.sell_plus_volume,
    },
  ];
  const buyVolumes = [
    {
      buyMinusVolume: volumes.buy_minus_volume,
      buyExactVolume: volumes.buy_exact_volume,
      buyPlusVolume: volumes.buy_plus_volume,
    },
  ];

  const listOfBuyVolumesColumns = [
    {
      title: 'Buy Minus Volume',
      key: 'buyMinusVolume',
      dataIndex: 'buyMinusVolume',
    },
    {
      title: 'Buy Exact Volume',
      key: 'buyExactVolume',
      dataIndex: 'buyExactVolume',
    },
    {
      title: 'Buy Plus Volume',
      key: 'buyPlusVolume',
      dataIndex: 'buyPlusVolume',
    },
  ];

  const listOfSellVolumesColumns = [
    {
      title: 'Sell Minus Volume',
      key: 'sellMinusVolume',
      dataIndex: 'sellMinusVolume',
    },
    {
      title: 'Sell Exact Volume',
      key: 'sellExactVolume',
      dataIndex: 'sellExactVolume',
    },
    {
      title: 'Sell Plus Volume',
      key: 'sellPlusVolume',
      dataIndex: 'sellPlusVolume',
    },
  ];

  return (
    <div>
      <Col className="base-content br-t br-b br-l br-r">
        <Space className="batcher-price" direction="vertical">
          <Row>
            <Col className="mr-c" span={12}>
              <p className="font-mono p-16">Volumes</p>
            </Col>
          </Row>
          <Space size="large" />
          <Row className="text-center">
            <table>
              <thead>
                {listOfBuyVolumesColumns.map((b) => (
                  <td>{b.title}</td>
                ))}
              </thead>
              <tbody>
                {listOfBuyVolumesColumns.map((b) => {
                  console.log("buyVolumes[b.key]", buyVolumes[b.key]);
                  console.log("buyVolumes", buyVolumes);
                  return <td>{buyVolumes[b.key]}</td>;
                })}
              </tbody>
            </table>
            {/* <Table
                className="batcher-table ant-typeography center"
                columns={listOfBuyVolumesColumns}
                rowKey="buyMinusVolume"
                dataSource={buyVolumes}
                pagination={false}
              /> */}
          </Row>
          <Space size="large" />
          <Row className="text-center">
            <Col lg={3} />
            <Col lg={18} xs={24}>
              <Table
                className="batcher-table ant-typeography center"
                columns={listOfSellVolumesColumns}
                rowKey="sellMinusVolume"
                dataSource={sellVolumes}
                pagination={false}
              />
            </Col>
            <Col lg={3} />
          </Row>
        </Space>
      </Col>
    </div>
  );
};

export default Volume;
