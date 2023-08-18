// Tzkt Websocket
import { HubConnectionBuilder, HubConnectionState } from '@microsoft/signalr';
import { now } from 'moment';
export const connection = new HubConnectionBuilder()
  .withUrl(process.env.NEXT_PUBLIC_TZKT_URI_API + '/v1/ws')
  .build();

function isReady() {
  return connection.state === HubConnectionState.Connected;
}

function isNotReady() {
  return !isReady();
}

function sleep(ms: number) {
  console.info(`Sleeping (${ms} ms)`, now());
  return new Promise(resolve => setTimeout(resolve, ms));
}

const assure_connection = async () => {
  try {
    if (connection.state === HubConnectionState.Disconnected) {
      console.log(
        'SOCKET CONNECTION:  was disconnected - starting',
        connection.state
      );
      await connection.start();
    }
    let retries = 10;
    while (isNotReady()) {
      if (retries > 0) {
        console.log(
          'SOCKET CONNECTION: connection not ready retrying ' + retries,
          connection.state
        );
        retries = retries - 1;
        await sleep(2000);
      } else {
        return;
      }
    }
  } catch (error: any) {
    console.error(error);
  }
};

export const init_contract = async () => {
  const batcherContractHash = process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH;

  await assure_connection()
    .then(() => {
      console.log('SOCKET CONNECTION:  connecting bigmaps', connection.state);
      if (isReady()) {
        // Subscription to Batcher oracle rates
        connection.invoke('SubscribeToBigMaps', {
          contract: batcherContractHash,
        });
      }
    })
    .then(() => {
      console.log(
        'SOCKET CONNECTION:  connecting operations',
        connection.state
      );
      if (isReady()) {
        // Subscription to Batcher operations
        connection.invoke('SubscribeToOperations', {
          address: batcherContractHash,
          types: 'transaction',
        });
      }
    });
};

export const init_user = async (userAddress: string | undefined) => {
  try {
    await assure_connection().then(() => {
      if (isReady()) {
        if (userAddress) {
          // Subscription to token balances
          console.log('SOCKET CONNECTION:  connecting token balances', connection.state);
          connection.invoke('SubscribeToTokenBalances', {
            account: userAddress,
          });
        }
      }
    });
  } catch (error) {
    console.error('Unable to init connection', error);
  }
};
