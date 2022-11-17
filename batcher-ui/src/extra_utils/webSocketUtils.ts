// Tzkt Websocket
import { HubConnectionBuilder } from '@microsoft/signalr';

export const connection = new HubConnectionBuilder()
  .withUrl(REACT_APP_TZKT_URI_API + '/v1/ws')
  .build();

export const init = async (userAddress: string) => {
  await connection.stop();

  await connection.start();

  // Subscription to tzBTC contract
  await connection.invoke('SubscribeToTokenBalances', {
    account: userAddress,
    contract: REACT_APP_TZBTC_HASH,
  });

  // Subscription to USDT contract
  await connection.invoke('SubscribeToTokenBalances', {
    account: userAddress,
    contract: REACT_APP_USDT_HASH,
  });

  // Subscription to Batcher operations
  await connection.invoke('SubscribeToOperations', {
    address: REACT_APP_BATCHER_CONTRACT_HASH,
    types: 'transaction',
  });

  // Subscription to Batcher oracle rates
  await connection.invoke('SubscribeToBigMaps', {
    contract: REACT_APP_BATCHER_CONTRACT_HASH,
  });
};
