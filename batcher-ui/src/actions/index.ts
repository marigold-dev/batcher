import { TezosToolkit } from '@taquito/taquito';
import { WalletActions } from './wallet';
import { AppState } from 'src/reducers';
export * from './wallet';

export const setupTezosToolkit = () =>
  ({
    type: 'SETUP_TEZOS_TOOLKIT',
  } as const);

export const tezosToolkitSetuped = (tezos: TezosToolkit) =>
  ({
    type: 'TEZOS_TOOLKIT_SETUPED',
    payload: { tezos },
  } as const);

export const hydrateBatcherState = (
  batcherState: Pick<AppState, 'userAccount' | 'userAddress' | 'wallet'>
) =>
  ({
    type: 'HYDRATE_BATCHER_STATE',
    payload: { batcherState },
  } as const);

export type Actions =
  | WalletActions
  | ReturnType<typeof setupTezosToolkit>
  | ReturnType<typeof tezosToolkitSetuped>
  | ReturnType<typeof hydrateBatcherState>;
