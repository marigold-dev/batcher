import { TezosToolkit } from '@taquito/taquito';
import { BatcherStatus } from 'src/types';

export const setupTezosToolkit = () =>
  ({
    type: 'SETUP_TEZOS_TOOLKIT',
  } as const);

export const tezosToolkitSetuped = (tezos: TezosToolkit) =>
  ({
    type: 'TEZOS_TOOLKIT_SETUPED',
    payload: { tezos },
  } as const);

export const updateBatcherStatus = (status: BatcherStatus) =>
  ({
    type: 'UDPATE_BATCHER_STATUS',
    payload: { status },
  } as const);

export type MiscActions =
  | ReturnType<typeof setupTezosToolkit>
  | ReturnType<typeof tezosToolkitSetuped>
  | ReturnType<typeof updateBatcherStatus>;
