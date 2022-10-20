import { Input, Button, Space, Typography, Col, Row, InputNumber, Table } from 'antd';
import { useEffect, useState, React } from 'react';
import { ContractsService } from '@dipdup/tzkt-api';
import * as model from "../../model";

const OrderBook =  ({contractAddress, buyToken, sellToken}) => {

   //State
   const [currentBatchExists, setCurrentBatchExists] = useState<boolean>(false);
   const [orderBook, setOrderBook] = useState<model.order_book | undefined>(undefined);
   const [listOfOrders, setListOfOrders] = useState<Array<model.list_of_orders>>([]);
   const [aggregateOrders, setAggregateOrders] = useState<Array<model.aggregate_orders>>([]);
   const leftAggName = buyToken.name + " -> " + sellToken.name;
   const rightAggName = sellToken.name + " -> " + buyToken.name;

   // State Methods
   const chain_api_uri = process.env["REACT_APP_TZT_URI_API"];
   const contractsService = new ContractsService({ baseUrl: chain_api_uri, version:"", withCredentials:false});

   const aggregateAmounts = (orders: Array<model.swap_order>) => {
      return  orders.reduce((prev, order) =>{
           prev += Number(order.swap.from.amount);
           return prev;
       },0)
   };

   const to_string_tolerance = (tolerance:model.Tolerance) => {
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

   const to_order_for_list = (isBuySide:boolean, order: model.swap_order) => {
      return {
        ordertype: isBuySide ? leftAggName : rightAggName,
        price: to_string_tolerance(order.tolerance) ,
        value: order.swap.from.amount,
      }
   };

   const update_list_of_orders = async () => {
     let lofo : Array<model.list_of_orders> = [];

     if(orderBook!=undefined){
       orderBook.bids.map((o) => to_order_for_list(true,o)).forEach(o => lofo.push(o));
       orderBook.asks.map((o) => to_order_for_list(true,o)).forEach(o => lofo.push(o));
     }
     setListOfOrders(lofo);
   };

    const update_aggregate_orders = async () => {
     let buySideAmount = 0;
     let sellSideAmount = 0;

     if(orderBook!=undefined){
       buySideAmount = aggregateAmounts(orderBook.bids);
       sellSideAmount = aggregateAmounts(orderBook.asks);

      let agg_ord : model.aggregate_orders =
        {
          buyside: buySideAmount,
          sellside: sellSideAmount
        };

        setAggregateOrders([ agg_ord ]);
     }
    };

   const update_orders = async () => {

     const storage = await contractsService.getStorage({address : contractAddress, level: 0, path: null});

     let current_batch = undefined;

     try{
        current_batch = await storage.batches.current;
     }
      catch {}

     setCurrentBatchExists(current_batch == undefined ? false : true);

     if (currentBatchExists) {
       const order_book : model.order_book = storage.batches.current.orderbook;
       setOrderBook(order_book);
       update_list_of_orders();
       update_aggregate_orders();
     } else {
       setListOfOrders([]);
       setAggregateOrders([]);
     }
   };

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

 aggregateOrders.map((orders : model.aggregate_orders) => {
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

 listOfOrders.map((orders : model.list_of_orders) => {
   listOfOrdersData.push({
     ordertype: orders.ordertype,
     price: orders.price,
     value: orders.value,
   })
   return listOfOrdersData;
 });

  useEffect(() => {
    (async () => update_orders())();
  },contractAddress );

  return (
                <Space className="batcher-price" direction="vertical">
                  <Space size="large">
                    <Typography className="batcher-title p-16">Order Book</Typography>
                  </Space>
                  <Table className="batcher-table ant-typeography" columns={aggregateOrdersColumns} dataSource={aggregateOrdersData} pagination={false} />
                  <Space size="large"></Space>
                  <Table className="batcher-table ant-typeography" columns={listOfOrdersColumns} dataSource={listOfOrdersData} pagination={false} />
                </Space>
  );
};

export default OrderBook;
