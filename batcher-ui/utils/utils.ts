import { add, differenceInMinutes, parseISO } from 'date-fns';
import {
  BatcherStatus,
  CurrentSwap,
  VolumesState,
  VolumesStorage,
} from '../src/types';
import * as types from './types';
import { Dispatch, SetStateAction } from 'react';

export const setTokenAmount = (
  balances: any[],
  standardBalance: number,
  tokenAddress: string,
  tokenDecimals: number,
  setBalance: Dispatch<SetStateAction<number>>
) => {
  const item = balances.find(
    item => item.token.contract.address === tokenAddress
  );
  const tokAmount = item ? parseInt(item.balance) / 10 ** tokenDecimals : 0;
  setBalance(tokAmount);
};

export const scaleAmountDown = (amount: number, decimals: number) => {
  const scale = 10 ** -decimals;
  return amount * scale;
};
export const scaleAmountUp = (amount: number, decimals: number) => {
  const scale = 10 ** decimals;
  return amount * scale;
};

export const setSocketTokenAmount = (
  balances: any[],
  userAddress: string | undefined,
  token: types.token,
  setBalance: Dispatch<SetStateAction<number>>
) => {
  const item = balances.find(
    item =>
      item.account.address === userAddress &&
      item.token.contract.address === token.address
  );
  const tokAmount = item ? parseInt(item.balance) / 10 ** token.decimals : 0;
  setBalance(tokAmount);
};

// Contract error codes
var error_codes = new Map([
  [100, 'No rate available for swap '],
  [101, 'Invalid token address '],
  [102, 'Invalid tezos address'],
  [103, 'No open batch for deposits'],
  [104, 'Batch should be cleared'],
  [105, 'Trying to close batch which is not open'],
  [106, 'Unable to parse side from external order'],
  [107, 'Unable to parse tolerance from external order'],
  [108, 'Token standard not found'],
  [109, 'Xtz not currently supported'],
  [110, 'Unsupported swap type'],
  [111, 'Unable to reduce token amount to less than zero'],
  [112, 'Too many unredeemed orders'],
  [113, 'Insufficient swap fee'],
  [114, 'Sender not administrator'],
  [115, 'Token already exists but details are different'],
  [116, 'Swap already exists'],
  [117, 'Swap does not exist'],
  [118, 'Endpoint does not accept tez'],
  [119, 'Number is not a nat'],
  [120, 'Oracle price is stale'],
  [121, 'Oracle price is not timely'],
  [122, 'Unable to get price from oracle'],
  [123, 'Unable to get price from new oracle source'],
  [124, 'Oracle price should be available before deposit'],
  [125, 'Swap is disabled for deposits'],
  [126, 'Upper limit on tokens has been reached'],
  [127, 'Upper limit on swap pairs has been reached'],
  [128, 'Cannot reduce limit on tokens to less than already exists'],
  [129, 'Cannot reduce limit on swap pairs to less than already exists'],
  [130, 'More tez sent than fee cost'],
  [131, 'Cannot update deposit window to less than the minimum'],
  [132, 'Cannot update deposit window to more than the maximum'],
  [133, 'Oracle must be equal to minimum precision'],
  [134, 'Swap precision is less than minimum'],
  [135, 'Cannot update scale factor to less than the minimum'],
  [136, 'Cannot update scale factor to more than the maximum'],
  [137, 'Cannot remove swap pair that is not disabled'],
]);
export const getErrorMess = (error: any) => {
  try {
    console.info('Error Message', error);
    const error_data_size = error.data.length;
    console.info('Error Data Length', error_data_size);
    const error_code = error.data[error_data_size - 1].with.int;
    const error_message = error_codes.get(parseInt(error_code));
    return error_message;
  } catch {
    return error instanceof Error ? error.message : 'Unknown error';
  }
};

export const orders_exist_in_order_book = (ob: types.order_book) => {
  try {
    return ob.bids.length > 0 || ob.asks.length > 0;
  } catch {
    return false;
  }
};

export const getEmptyOrderBook = () => {
  return {
    bids: [],
    asks: [],
  };
};

export const getNetworkType = () => {
  const network = process.env.NEXT_PUBLIC_NETWORK_TARGET;
  if (network?.includes('GHOSTNET')) {
    return types.NetworkType.GHOSTNET;
  } else {
    return types.NetworkType.MAINNET;
  }
};

export const getEmptyVolumes = () => {
  return {
    buy_minus_volume: '0',
    buy_exact_volume: '0',
    buy_plus_volume: '0',
    sell_minus_volume: '0',
    sell_exact_volume: '0',
    sell_plus_volume: '0',
  };
};

export const scaleStringAmountDownToString = (
  amount: string,
  decimals: number
) => {
  if (!amount) {
    console.error(
      'scaleStringAmountDownToString - amount is undefined',
      amount
    );
    return '0';
  } else {
    const scale = 10 ** -decimals;
    return (Number.parseInt(amount) * scale).toString();
  }
};

export const zeroHoldings = (
  storage: any,
  setOpenHoldings: Dispatch<SetStateAction<Map<string, number>>>,
  setClearedHoldings: Dispatch<SetStateAction<Map<string, number>>>
) => {
  const valid_pairs = storage?.valid_tokens;
  const ot = new Map<string, number>();
  const ct = new Map<string, number>();
  if (valid_pairs) {
    Object.keys(valid_pairs).map((k, i) => {
      ot.set(k, 0);
      ct.set(k, 0);
    });
    setClearedHoldings(ct);
    setOpenHoldings(ot);
  }
};

// ----- BALANCES ------

export type Balances = {
  name: string;
  balance: number;
  decimals: number;
}[];

// TODO: need to configure token available in Batcher
export const TOKENS = ['USDT', 'EURL', 'TZBTC'];

/**
 * Use to convert balances raw JSON from TZKT API to smooth Object
 */
export const toUserBalances = (rawBalances: any[]): Balances => {
  return rawBalances.map(rawB => ({
    name: rawB.token.metadata.symbol,
    balance: rawB.balance,
    decimals: rawB.token.metadata.decimals,
  }));
};

export const filterBalances = (balances: Balances): Balances => {
  return balances.filter(b => TOKENS.includes(b.name.toUpperCase()));
};

export const storeBalances = (balances: any[]) =>
  filterBalances(toUserBalances(balances));

// ----- STORAGE ------

export const getStorageByAddress = (address: string): Promise<any> =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/contracts/${address}/storage`
  ).then(r => r.json());

export const getPairsInformations = async (
  pair: string,
  address: string
): Promise<{ currentSwap: CurrentSwap; pair: string }> => {
  const storage = await getStorageByAddress(address);
  const validTokens = storage['valid_tokens'];
  const pairs = pair.split('/');

  return {
    currentSwap: {
      swap: {
        from: {
          token: validTokens[pairs[0]],
          amount: 0,
        },
        to: validTokens[pairs[1]],
      },
      isReverse: false,
    },
    pair,
  };
};

export const getFees = async (address: string) => {
  const storage = await getStorageByAddress(address);
  const feeInMutez: number = storage['fee_in_mutez'];
  return feeInMutez;
};

export const getCurrentBatchNumber = async (
  address: string,
  pair: string
): Promise<number> => {
  const storage = await getStorageByAddress(address);
  const currentBatchIndices = storage['batch_set']['current_batch_indices'];
  return currentBatchIndices[pair];
};

export const getBigMapByIdAndBatchNumber = (
  bigMapId: number,
  batchNumber: number
) =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigMapId}/keys/${batchNumber}`
  )
    .then(r => r.json())
    .then(r => r.value);

export const getBigMapByIdAndTokenPair = (
  bigMapId: number,
  tokenPair: string
) =>
  //TODO: type response
  fetch(`${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigMapId}/keys`)
    .then(r => r.json())
    .then(response =>
      response.filter((r: any) => r.key === tokenPair).map((r: any) => r.value)
    );

const toBatcherStatus = (rawStatus: string): BatcherStatus => {
  switch (rawStatus) {
    case 'cleared':
      return BatcherStatus.CLEARED;
    case 'closed':
      return BatcherStatus.CLOSED;
    case 'open':
      return BatcherStatus.OPEN;
    default:
      return BatcherStatus.NONE;
  }
};

const getStatusTime = (status: string, batch: any) => {
  switch (status) {
    case 'open':
      return batch.status[status];
    case 'closed':
      return batch.status[status].closing_time;
    case 'cleared':
      return batch.status[status].at;
    default:
      return null;
  }
};

const getStartTime = (status: string, batch: any) => {
  switch (status) {
    case 'open':
      return batch.status[status];
    case 'closed':
      return batch.status[status].start_time;
    default:
      return null;
  }
};

export const getBatcherStatus = async (
  batchNumber: number,
  address: string
): Promise<{ status: BatcherStatus; at: string; startTime: string | null }> => {
  const storage = await getStorageByAddress(address);
  const batch = await getBigMapByIdAndBatchNumber(
    storage['batch_set']['batches'],
    batchNumber
  );
  const status = Object.keys(batch.status)[0];
  return {
    status: toBatcherStatus(status),
    at: new Date(getStatusTime(status, batch)).toISOString(),
    startTime: getStartTime(status, batch)
      ? new Date(getStartTime(status, batch)).toISOString()
      : null,
  };
};

export const getTimeDifference = (
  status: BatcherStatus,
  startTime: string | null
) => {
  if (status === BatcherStatus.OPEN && startTime) {
    const now = new Date();
    const open = parseISO(startTime);
    const batcherClose = add(open, { minutes: 10 });
    const diff = differenceInMinutes(batcherClose, now);
    return diff < 0 ? 0 : diff;
  }
  return 0;
};

export const getCurrentRates = async (tokenPair: string, address: string) => {
  const storage = await getStorageByAddress(address);
  const ratesCurrent = await getBigMapByIdAndTokenPair(
    storage['rates_current'],
    tokenPair
  );

  return ratesCurrent;
};

// TODO: make types
export const computeOraclePrice = (rates: any, currentSwap: CurrentSwap) => {
  const numerator = rates.rate.p;
  const denominator = rates.rate.q;
  const { swap } = currentSwap;
  const scaledPow = swap.from.token.decimals - swap.to.decimals;
  const scaledRate = scaleAmountUp(numerator / denominator, scaledPow);
  return scaledRate;
};

// ---- VOLUMES ----

export const scaleStringAmountDown = (amount: string, decimals: number) => {
  if (!amount) {
    console.error('scaleStringAmountDown - amount is undefined', amount);
    return 0;
  } else {
    const scale = 10 ** -decimals;
    return Number.parseInt(amount) * scale;
  }
};

const toVolumes = (
  rawVolumes: VolumesStorage,
  { buyDecimals, sellDecimals }: { buyDecimals: number; sellDecimals: number }
): VolumesState => {
  return {
    sell: {
      BETTER: scaleStringAmountDown(rawVolumes.sell_plus_volume, sellDecimals),
      EXACT: scaleStringAmountDown(rawVolumes.sell_exact_volume, sellDecimals),
      WORSE: scaleStringAmountDown(rawVolumes.sell_minus_volume, sellDecimals),
    },
    buy: {
      BETTER: scaleStringAmountDown(rawVolumes.buy_plus_volume, buyDecimals),
      EXACT: scaleStringAmountDown(rawVolumes.buy_exact_volume, buyDecimals),
      WORSE: scaleStringAmountDown(rawVolumes.buy_minus_volume, buyDecimals),
    },
  };
};

export const getVolumes = async (
  batchNumber: number,
  currentSwap: CurrentSwap,
  address: string
) => {
  const storage = await getStorageByAddress(address);
  const batch = await getBigMapByIdAndBatchNumber(
    storage['batch_set']['batches'],
    batchNumber
  );
  return toVolumes(batch['volumes'], {
    buyDecimals: currentSwap.swap.to.decimals,
    sellDecimals: currentSwap.swap.from.token.decimals,
  });
};