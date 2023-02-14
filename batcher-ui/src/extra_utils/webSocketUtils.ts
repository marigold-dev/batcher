// Tzkt Websocket
import { HubConnectionBuilder } from '@microsoft/signalr';
export const connection = new HubConnectionBuilder()
  .withUrl(REACT_APP_TZKT_URI_API + '/v1/ws')
  .build();

export const init = async (userAddress: string) => {
  try{
   await connection.stop();
   console.log("CONN state",connection.state);

  await connection.start();

  // Subscription to Batcher oracle rates
  await connection.invoke('SubscribeToBigMaps', {
    contract: REACT_APP_BATCHER_CONTRACT_HASH,
  });

  // Subscription to token balances
  await connection.invoke('SubscribeToTokenBalances', {
      account: userAddress,
  });

  // Subscription to Batcher operations
  await connection.invoke('SubscribeToOperations', {
    address: REACT_APP_BATCHER_CONTRACT_HASH,
    types: 'transaction',
  });
    console.log('CONNECTION', connection);
    } catch (error) {
      console.error('Unable to init connection', error);
    }

};
