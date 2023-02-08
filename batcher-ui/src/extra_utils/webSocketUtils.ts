// Tzkt Websocket
import { HubConnectionBuilder } from '@microsoft/signalr';

export const connection = new HubConnectionBuilder()
  .withUrl(REACT_APP_TZKT_URI_API + '/v1/ws')
  .build();

export const init = async (userAddress: string, buy_token_hash:string, sell_token_hash:string) => {
  await connection.stop();

  await connection.start();


  // Subscription to Batcher operations
  await connection.invoke('SubscribeToOperations', {
    address: REACT_APP_BATCHER_CONTRACT_HASH,
    types: 'transaction',
  });

  // Subscription to Batcher oracle rates
  await connection.invoke('SubscribeToBigMaps', {
    contract: REACT_APP_BATCHER_CONTRACT_HASH,
  });

  await connection.invoke('SubscribeToTokenBalances', {
      account: userAddress,
      contract: buy_token_hash,
  });

  await connection.invoke('SubscribeToTokenBalances', {
      account: userAddress,
      contract: sell_token_hash,
  });

};
