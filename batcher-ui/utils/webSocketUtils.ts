import { HubConnection, HubConnectionState } from '@microsoft/signalr';

const subscribeBigMaps = (socket: HubConnection) => {
  const batcherContractHash = process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH;

  return socket.invoke('SubscribeToBigMaps', {
    contract: batcherContractHash,
  });
};

export const subscribeTokenBalances = (
  socket: HubConnection | undefined,
  userAddress: string | undefined
) => {
  if (!socket || socket.state !== HubConnectionState.Connected)
    return Promise.reject('No socket connection');
  if (userAddress) {
    return socket
      .invoke('SubscribeToTokenBalances', {
        account: userAddress,
      })
      .then(() => {
        console.info('Socket connected to token balances updates.');
      });
  }
  return Promise.reject('No address');
};

const subscribeOperations = (socket: HubConnection) => {
  const batcherContractHash = process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH;

  return socket.invoke('SubscribeToOperations', {
    address: batcherContractHash,
    types: 'transaction',
  });
};

export const setup = async (socket: HubConnection) => {
  if (socket.state === HubConnectionState.Disconnected) {
    await socket.start();
    subscribeBigMaps(socket).then(() => {
      console.info('Socket connected to bigMaps updates.', socket.state);
    });

    socket.onclose(error => {
      if (error) console.error('Error with socket : ', error);
      setup(socket);
    });
  }
};
