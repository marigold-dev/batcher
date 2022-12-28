import React, { useEffect, useState } from 'react';
import { Button, Space, Typography, Col, Row, Table } from 'antd';
import '@/components/Exchange/index.less';
import '@/components/OrderBook/index.less';
import '@/global.less';
import {
  OrderBookProps,
  list_of_orders,
  aggregate_orders,
  swap_order,
  Tolerance,
} from '@/extra_utils/types';
import { orders_exist_in_order_book, scaleAmountDown } from '@/extra_utils/utils';
import { ColumnsType } from 'antd/es/table';

const { Text } = Typography;

const OrderBook: React.FC<OrderBookProps> = ({
  orderBook,
  buyToken,
  sellToken,
}: OrderBookProps) => {
  interface AggregateOrder {
    index: number;
    buyside: number;
    sellside: number;
  }
  interface OrderListItem {
    order_number: number;
    ordertype: string;
    price: string;
    value: number;
  }
  const [aggregateOrdersForTable, setAggregateOrdersForTable] = useState<Array<AggregateOrder>>([]);
  const [orderListForTable, setOrderListForTable] = useState<Array<OrderListItem>>([]);
  const [orderListForTableExpanded, setOrderListForTableExpanded] = useState<Array<OrderListItem>>(
    [],
  );
  const [expandedView, setExpandedView] = useState<boolean>(false);
  const leftAggName = buyToken.name + ' -> ' + sellToken.name;
  const rightAggName = sellToken.name + ' -> ' + buyToken.name;

  const aggregateAmounts = (orders: Array<swap_order>) => {
    return orders.reduce((prev, order) => {
      prev += Number(order.swap.from.amount);
      return prev;
    }, 0);
  };

  const to_string_tolerance = (tolerance: Tolerance) => {
    if (tolerance.eXACT != undefined) {
      return 'Oracle Price';
    }

    if (tolerance.mINUS != undefined) {
      return 'W.price/ B.fill';
    }

    if (tolerance.pLUS != undefined) {
      return 'B.price/ W.fill';
    }

    return 'Oracle Price';
  };

  const to_order_for_list = (isBuySide: boolean, order: swap_order) => {
    return {
      ordertype: isBuySide ? leftAggName : rightAggName,
      price: to_string_tolerance(order.tolerance),
      value: isBuySide
        ? scaleAmountDown(order.swap.from.amount, buyToken.decimals)
        : scaleAmountDown(order.swap.from.amount, sellToken.decimals),
    };
  };

  const update_list_of_orders = async () => {
    let lofo: Array<list_of_orders> = [];

    if (orders_exist_in_order_book(orderBook)) {
      orderBook.bids.map((o) => to_order_for_list(true, o)).forEach((o) => lofo.push(o));
      orderBook.asks.map((o) => to_order_for_list(false, o)).forEach((o) => lofo.push(o));
    }

    const list_orders_for_table = lofo.map((o: list_of_orders, index) => {
      const modified: OrderListItem = {
        order_number: index + 1,
        ordertype: o.ordertype,
        price: o.price,
        value: o.value,
      };
      return modified;
    });
    setOrderListForTableExpanded(list_orders_for_table);
    setOrderListForTable(list_orders_for_table.slice(0, 3));
  };

  const update_aggregate_orders = async () => {
    let buySideAmount = 0;
    let sellSideAmount = 0;

    if (orders_exist_in_order_book(orderBook)) {
      buySideAmount = scaleAmountDown(aggregateAmounts(orderBook.bids), buyToken.decimals);
      sellSideAmount = scaleAmountDown(aggregateAmounts(orderBook.asks), sellToken.decimals);

      let agg_ord: aggregate_orders = {
        buyside: buySideAmount,
        sellside: sellSideAmount,
      };

      const agg_orders_for_table = [agg_ord].map((ao: aggregate_orders, index) => {
        const modified: AggregateOrder = {
          index: index + 1,
          buyside: ao.buyside,
          sellside: ao.sellside,
        };
        return modified;
      });
      setAggregateOrdersForTable(agg_orders_for_table);
    }
  };

  const update_orders = async () => {
    if (orders_exist_in_order_book(orderBook)) {
      update_list_of_orders();
      update_aggregate_orders();
    } else {
      setOrderListForTableExpanded([]);
      setOrderListForTable([]);
      setAggregateOrdersForTable([]);
    }
  };

  useEffect(() => {
    update_orders();
  }, [orderBook]);

  const setView = () => {
    setExpandedView(!expandedView);
  };

  const aggregateOrdersColumns: ColumnsType<AggregateOrder> = [
    {
      title: leftAggName,
      key: 'buyside',
      dataIndex: 'buyside',
    },
    {
      title: rightAggName,
      key: 'sellside',
      dataIndex: 'sellside',
    },
  ];

  const listOfOrdersColumns = [
    {
      title: 'Order #',
      key: 'order_number',
      dataIndex: 'order_number',
    },
    {
      title: 'Order type',
      key: 'ordertype',
      dataIndex: 'ordertype',
    },
    {
      title: 'Price',
      key: 'price',
      dataIndex: 'price',
    },
    {
      title: 'Value',
      key: 'value',
      dataIndex: 'value',
    },
  ];

  return (
    <div>
      <Col className="base-content br-t br-b br-l br-r">
        <Space className="batcher-price" direction="vertical">
          <Row>
            <Col className="mr-c" span={12}>
              <Typography className="batcher-title p-16">OrderBook</Typography>
            </Col>
          </Row>
          <Row>
            <Col lg={3} />
            <Col lg={18} xs={24}>
              <Table
                className="batcher-table ant-typeography center col-offset-6"
                columns={aggregateOrdersColumns}
                rowKey="index"
                dataSource={aggregateOrdersForTable}
                pagination={false}
              />
            </Col>
            <Col lg={3} />
          </Row>
          <Space size="large" />
          <Row className="text-center">
            <Col lg={3} />
            <Col lg={18} xs={24}>
              <Table
                className="batcher-table ant-typeography center"
                columns={listOfOrdersColumns}
                rowKey="order_number"
                dataSource={expandedView ? orderListForTableExpanded : orderListForTable}
                pagination={false}
              />
            </Col>
            <Col lg={3} />
          </Row>
          <Space size="large" />
          <Row className="text-center">
            <Col span={12} offset={6}>
              <Button className="batcher-nav-btn" onClick={() => setView()}>
                <Text underline>{expandedView ? 'See less' : 'See more'}</Text>
              </Button>
            </Col>
          </Row>
        </Space>
      </Col>
    </div>
  );
};

export default OrderBook;
