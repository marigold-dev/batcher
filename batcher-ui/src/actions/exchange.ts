import { BatcherStatus, CurrentSwap, PriceStrategy } from '../types';

export const updatePriceStrategy = (priceStrategy: PriceStrategy) =>
  ({
    type: 'UDPATE_PRICE_STATEGY',
    payload: { priceStrategy },
  } as const);

export const reverseSwap = () =>
  ({
    type: 'REVERSE_SWAP',
  } as const);

export const changePair = (pair: string, isReverse: boolean) =>
  ({
    type: 'CHANGE_PAIR',
    payload: { pair, isReverse },
  } as const);

export const getPairsInfos = (pair: string) =>
  ({
    type: 'GET_PAIR_INFOS',
    payload: { pair },
  } as const);

export const updatePairsInfos = ({
  currentSwap,
  pair,
}: {
  currentSwap: Omit<CurrentSwap, 'isReverse'>;
  pair: string;
}) =>
  ({
    type: 'UPDATE_PAIR_INFOS',
    payload: { currentSwap, pair },
  } as const);

export const getBatcherStatus = () =>
  ({
    type: 'GET_BATCHER_STATUS',
  } as const);

export const updateBatcherStatus = ({
  status,
  at,
  startTime,
}: {
  status: BatcherStatus;
  at: string;
  startTime: string | null;
}) =>
  ({
    type: 'UDPATE_BATCHER_STATUS',
    payload: { status, at, startTime },
  } as const);

export const getCurrentBatchNumber = () =>
  ({
    type: 'GET_CURRENT_BATCHER_NUMBER',
  } as const);

export const updateBatchNumber = (batchNumber: number) =>
  ({
    type: 'UDPATE_BATCH_NUMBER',
    payload: { batchNumber },
  } as const);

export const batcherSetup = () =>
  ({
    type: 'BATCHER_SETUP',
  } as const);

export const batcherTimerId = (timerId: number) =>
  ({
    type: 'BATCHER_TIMER_ID',
    payload: { timerId },
  } as const);

export const batcherUnsetup = () =>
  ({
    type: 'BATCHER_UNSETUP',
  } as const);

export const getOraclePrice = () =>
  ({
    type: 'GET_ORACLE_PRICE',
  } as const);

export const updateOraclePrice = (oraclePrice: number) =>
  ({
    type: 'UPDATE_ORACLE_PRICE',
    payload: { oraclePrice },
  } as const);

export const getVolumes = () =>
  ({
    type: 'GET_VOLUMES',
  } as const);

export const updateVolumes = (volumes: unknown) =>
  ({
    type: 'UPDATE_VOLUMES',
    payload: { volumes },
  } as const);

export type ExchangeActions =
  | ReturnType<typeof updatePriceStrategy>
  | ReturnType<typeof reverseSwap>
  | ReturnType<typeof changePair>
  | ReturnType<typeof getPairsInfos>
  | ReturnType<typeof updatePairsInfos>
  | ReturnType<typeof getBatcherStatus>
  | ReturnType<typeof updateBatcherStatus>
  | ReturnType<typeof getCurrentBatchNumber>
  | ReturnType<typeof updateBatchNumber>
  | ReturnType<typeof batcherSetup>
  | ReturnType<typeof batcherUnsetup>
  | ReturnType<typeof batcherTimerId>
  | ReturnType<typeof getOraclePrice>
  | ReturnType<typeof updateOraclePrice>
  | ReturnType<typeof getVolumes>
  | ReturnType<typeof updateVolumes>;
