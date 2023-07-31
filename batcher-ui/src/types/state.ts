import { BeaconWallet } from '@taquito/beacon-wallet';
import { BatcherStatus, PriceStrategy, Token } from './contract';
import { TezosToolkit } from '@taquito/taquito';
import { AccountInfo } from '@airgap/beacon-sdk';

export type CurrentSwap = {
  swapPairName: 'tzBTC/USDT' | 'tzBTC/EURL';
  swap: {
    from: {
      token: Token;
      amount: number;
    };
    to: Token;
  };
  isReverse: boolean;
};

export type MiscState = {
  settings: null;
  tezos: TezosToolkit | undefined;
  batcherStatus: BatcherStatus;
};

export type ExchangeState = {
  priceStrategy: PriceStrategy;
  currentSwap: CurrentSwap;
};


export type WalletState = {
  wallet: BeaconWallet | undefined;
  userAddress: string | undefined;
  userAccount: AccountInfo | undefined;
  userBalances: Record<string, number>;
  // userBalances: { name: string; balance: number }[];
};

export type AppState = {
  misc: MiscState;
  exchange: ExchangeState;
  wallet: WalletState;
};

// export const initState: AppState = {
//   wallet: { wallet: undefined, userAddress: undefined, userAccount: undefined },
//   misc: {
//     settings: null,
//     tezos: undefined,
//     batcherStatus: BatcherStatus.STARTED,
//   },
//   exchange: {
//     priceStrategy: PriceStrategy.EXACT,
//     currentSwap: {
//       swapPairName: 'tzBTC/USDT',
//       swap: {
//         from: {
//           token: {
//             token_id: 0,
//             name: 'tzBTC',
//             address: undefined,
//             decimals: 0,
//             standard: 'FA1.2 token',
//           },
//           amount: 0,
//         },
//         to: {
//           token_id: 0,
//           name: 'USDT',
//           address: undefined,
//           decimals: 0,
//           standard: 'FA1.2 token',
//         },
//       },
//       isReverse: false,
//     },
//   },
// };
