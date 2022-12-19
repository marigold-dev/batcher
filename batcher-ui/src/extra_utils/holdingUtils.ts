import { EXACT, MINUS, PLUS } from './types';

export const getClearing = (clearingKey: any, clearingRate: number, batch: any) => {
  console.log('%cMain.tsx line:104 batch', 'color: #007acc;', batch);

  if (clearingKey === MINUS) {
    let sellSideAmount = 0;
    if (Array.isArray(batch.value.orderbook.asks) && batch.value.orderbook.asks.length > 0) {
      sellSideAmount = batch.value.orderbook.asks.reduce((currentAmount, order) => {
        console.log(23333, order);
        if (Object.keys(order.tolerance)[0] === MINUS) {
          currentAmount += order.swap.from.amount;
        }
        return currentAmount;
      }, 0);
    }

    let buySideAmount = 0;
    if (Array.isArray(batch.value.orderbook.bids) && batch.value.orderbook.bids.length > 0) {
      buySideAmount = batch.value.orderbook.bids.reduce((currentAmount, order) => {
        currentAmount += order.swap.from.amount;
        return currentAmount;
      }, 0);
    }

    return Math.min(buySideAmount, sellSideAmount / clearingRate);
  } else if (clearingKey === EXACT) {
    let sellSideAmount = 0;
    if (Array.isArray(batch.value.orderbook.asks) && batch.value.orderbook.asks.length > 0) {
      sellSideAmount = batch.value.orderbook.asks.reduce((currentAmount, order) => {
        if (
          Object.keys(order.tolerance)[0] === MINUS ||
          Object.keys(order.tolerance)[0] === EXACT
        ) {
          currentAmount += order.swap.from.amount;
        }
        return currentAmount;
      }, 0);
    }

    let buySideAmount = 0;
    if (Array.isArray(batch.value.orderbook.bids) && batch.value.orderbook.bids.length > 0) {
      buySideAmount = batch.value.orderbook.bids.reduce((currentAmount, order) => {
        if (Object.keys(order.tolerance)[0] === EXACT || Object.keys(order.tolerance)[0] === PLUS) {
          currentAmount += order.swap.from.amount;
        }
        return currentAmount;
      }, 0);
    }

    return Math.min(buySideAmount, sellSideAmount / clearingRate);
  } else {
    let sellSideAmount = 0;
    if (Array.isArray(batch.value.orderbook.asks) && batch.value.orderbook.asks.length > 0) {
      sellSideAmount = batch.value.orderbook.asks.reduce((currentAmount, order) => {
        currentAmount += order.swap.from.amount;
        return currentAmount;
      }, 0);
    }

    let buySideAmount = 0;
    if (Array.isArray(batch.value.orderbook.bids) && batch.value.orderbook.bids.length > 0) {
      buySideAmount = batch.value.orderbook.bids.reduce((currentAmount, order) => {
        if (Object.keys(order.tolerance)[0] === EXACT) {
          currentAmount += order.swap.from.amount;
        }
        return currentAmount;
      }, 0);
    }

    return Math.min(buySideAmount, sellSideAmount / clearingRate);
  }
};
