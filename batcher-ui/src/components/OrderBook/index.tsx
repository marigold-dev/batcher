import React, { useEffect, useState } from 'react';
import { SwapOutlined } from '@ant-design/icons';
import { Input, Button, Space, Typography, Col, Row, InputNumber, Table } from 'antd';
import { useModel } from 'umi';
import '@/components/Exchange/index.less';
import '@/global.less';
import { OrderBookProps, list_of_orders, aggregate_orders, swap_order, Tolerance } from '@/extra_utils/types';

const { Text } = Typography;

const OrderBook: React.FC<OrderBookProps> = ({ orderBookExists, orderBook, buyToken, sellToken }: OrderBookProps) => {

  const { initialState } = useModel('@@initialState');
  const { wallet, userAddress } = initialState;
  const [listOfOrders, setListOfOrders] = useState<Array<list_of_orders>>([]);
  const [aggregateOrders, setAggregateOrders] = useState<Array<aggregate_orders>>([]);
  const leftAggName = buyToken.name + " -> " + sellToken.name;
  const rightAggName = sellToken.name + " -> " + buyToken.name;

   const aggregateAmounts = (orders: Array<swap_order>) => {
      return  orders.reduce((prev, order) =>{
           prev += Number(order.swap.from.amount);
           return prev;
       },0)
   };

   const to_string_tolerance = (tolerance:Tolerance) => {
      if (tolerance.eXACT != undefined){
         return "Oracle Price";
      }

      if (tolerance.mINUS != undefined){
         return "W. price/ B.fill";
      }

      if (tolerance.pLUS != undefined){
         return "B. price/ W.fill";
      }

      return "Oracle Price";
   };

   const to_order_for_list = (isBuySide:boolean, order: swap_order) => {
      return {
        ordertype: isBuySide ? leftAggName : rightAggName,
        price: to_string_tolerance(order.tolerance) ,
        value: order.swap.from.amount,
      }
   };

   const update_list_of_orders = async () => {
     let lofo : Array<list_of_orders> = [];

     if(!orderBookExists){
       orderBook.bids.map((o) => to_order_for_list(true,o)).forEach(o => lofo.push(o));
       orderBook.asks.map((o) => to_order_for_list(true,o)).forEach(o => lofo.push(o));
     }
     setListOfOrders(lofo);
   };

    const update_aggregate_orders = async () => {
     let buySideAmount = 0;
     let sellSideAmount = 0;

     if(!orderBookExists){
       buySideAmount = aggregateAmounts(orderBook.bids);
       sellSideAmount = aggregateAmounts(orderBook.asks);

      let agg_ord : aggregate_orders =
        {
          buyside: buySideAmount,
          sellside: sellSideAmount
        };

        setAggregateOrders([ agg_ord ]);
     }
    };

  const update_orders = async () => {
     if(orderBookExists){
        update_list_of_orders();
        update_aggregate_orders();

     } else {
       setListOfOrders([]);
       setAggregateOrders([]);
     }
  };

  useEffect(() => {
    (async () => update_orders())();
  }, [orderBookExists, orderBook]);

 const aggregateOrdersColumns = [
    {
     title: leftAggName,
     dataIndex: 'buyside',
    },
    {
     title: rightAggName,
     dataIndex: 'sellside',
    },
 ];

const aggregateOrdersData = [{}];

 aggregateOrders.map((orders : aggregate_orders) => {
   aggregateOrdersData.push({
     buyside: orders.buyside,
     sellside: orders.sellside,
   })
   return aggregateOrdersData;
 });

 const listOfOrdersColumns = [
    {
     title: 'Order type',
     dataIndex: 'ordertype',
    },
    {
     title: 'Price',
     dataIndex: 'price',
    },
    {
     title: 'Value',
     dataIndex: 'value',
    },
 ];

const listOfOrdersData = [{}];

 listOfOrders.map((orders : list_of_orders) => {
   listOfOrdersData.push({
     ordertype: orders.ordertype,
     price: orders.price,
     value: orders.value,
   })
   return listOfOrdersData;
 });




  return (
    <div>
              <Col className="base-content br-t br-b br-l br-r">
                <Space className="batcher-price" direction="vertical">
                  <Row>
                    <Col className="mr-c" span={12}>
                      <Typography className="batcher-title p-16">
                        OrderBook
                      </Typography>
                    </Col>
                  </Row>
                  <Row className="text-center">
                  <Col span={12} offset={6}>
                     <Table className="batcher-table ant-typeography center col-offset-6" columns={aggregateOrdersColumns} dataSource={aggregateOrdersData} pagination={false} />
                     </Col>
                  </Row>
                  <Space size="large" />
                  <Row className="text-center">
                  <Col span={12} offset={6}>
                  <Table className="batcher-table ant-typeography center" columns={listOfOrdersColumns} dataSource={listOfOrdersData} pagination={false} />
                     </Col>
                  </Row>
                </Space>
              </Col>
      </div>
  );
};

export default OrderBook;
