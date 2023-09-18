import { add, differenceInMinutes, parseISO } from 'date-fns';
import {
  BatcherStatus,
  CurrentSwap,
  Deposit,
  HoldingsState,
  Token,
  TokenNames,
  VolumesState,
  VolumesStorage,
  MarketMakerStorage,
  batchIsCleared,
  GlobalVault,
  UserVault,
  VaultToken,
  Vault,
  MarketHoldingsState,
  MVault,
  initialMVault,
} from '../types';
import { Batch } from 'src/types/events';
import { NetworkType } from '@airgap/beacon-sdk';
import * as api from '@tzkt/sdk-api';

export const scaleAmountDown = (amount: number, decimals: number) => {
  const scale = 10 ** -decimals;
  return amount * scale;
};
export const scaleAmountUp = (amount: number, decimals: number) => {
  const scale = 10 ** decimals;
  return amount * scale;
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

export const getNetworkType = () => {
  const network = process.env.NEXT_PUBLIC_NETWORK_TARGET;
  if (network?.includes('GHOSTNET')) {
    return NetworkType.GHOSTNET;
  } else {
    return NetworkType.MAINNET;
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

export const getBalances = async (
  address: string,
  userAddress: string
): Promise<Balances> => {
  const storage = await getStorageByAddress(address);
  const validTokens: Record<TokenNames, Token> = storage['valid_tokens'];
  const rawBalances = await api.tokensGetTokenBalances({
    account: {
      eq: userAddress,
    },
  });
  return Object.values(validTokens).map(token => {
    const balance = rawBalances.find(
      b => b.token?.contract?.address === token.address
    )?.balance;
    return {
      name: token.name,
      decimals: token.decimals,
      balance: balance
        ? scaleAmountDown(parseFloat(balance), token.decimals)
        : 0,
    };
  });
};

// ----- STORAGE ------

export const getStorageByAddress = (address: string): Promise<any> =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/contracts/${address}/storage`
  ).then(r => r.json());

export const getPairsInformations = async (
  pair: string,
  address: string
): Promise<{ currentSwap: Omit<CurrentSwap, 'isReverse'>; pair: string }> => {
  const storage = await getStorageByAddress(address);
  const validTokens = storage['valid_tokens'];
  const pairs = pair.split('/');

  return {
    currentSwap: {
      swap: {
        from: {
          token: {
            ...validTokens[pairs[0]],
            decimals: parseInt(validTokens[pairs[0]].decimals, 10),
          },
          amount: 0,
        },
        to: {
          ...validTokens[pairs[1]],
          decimals: parseInt(validTokens[pairs[1]].decimals, 10),
        },
      },
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
): Promise<number | undefined> => {
  const storage = await getStorageByAddress(address);
  const currentBatchIndices = storage['batch_set']['current_batch_indices'];
  return currentBatchIndices[pair];
};

export const getBigMapByIdAndUserAddress = (
  bigMapId: number,
  userAddress?: string
) => {
  if (!userAddress) return [];
  return (
    fetch(
      `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigMapId}/keys/${userAddress}`
    )
      // TODO: fix that
      .then(r => (r.status === 204 ? { value: [] } : r.json()))
      .then(r => r.value)
  );
};

export const getBigMapByIdAndKey = (bigMapId: number, key: string) =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigMapId}/keys/${key}`
  )
    // TODO: fix that
    .then(r => (r.status === 204 ? { value: [] } : r.json()))
    .then(r => r.value)
    .catch(error => console.log(error));

export const getBigMapByIdAndBatchNumber = (
  bigMapId: number,
  batchNumber: number
) =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigMapId}/keys/${batchNumber}`
  ).then(r => r.json());

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

export const computeOraclePrice = (
  rate: { p: number; q: number },
  { buyDecimals, sellDecimals }: { buyDecimals: number; sellDecimals: number }
) => {
  const numerator = rate.p;
  const denominator = rate.q;
  const scaledPow = sellDecimals - buyDecimals;
  return scaleAmountUp(numerator / denominator, scaledPow);
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

export const toVolumes = (
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

export const getVolumes = async (batchNumber: number, address: string) => {
  const storage = await getStorageByAddress(address);
  const batch = await getBigMapByIdAndBatchNumber(
    storage['batch_set']['batches'],
    batchNumber
  );
  return toVolumes(batch['volumes'], {
    buyDecimals: batch.pair.decimals_0,
    sellDecimals: batch.pair.decimals_1,
  });
};

// ---- HOLDINGS ----

const convertHoldingToPayout = (
  fromAmount: number, //! nb total que le user a deposé dans le batch
  fromVolumeSubjectToClearing: number, //! nb total que le user a deposé (que l'on pourrait clear)
  fromClearedVolume: number, //! nb total de tokens 'buy' qui a honoré l'ordre
  toClearedVolume: number, //! nb total de tokens 'sell' qui a honoré l'ordre
  fromDecimals: number,
  toDecimals: number
) => {
  const prorata = fromAmount / fromVolumeSubjectToClearing;
  const payout = toClearedVolume * prorata;
  const payoutInFromTokens = fromClearedVolume * prorata;
  const remainder = fromAmount - payoutInFromTokens;
  const scaled_payout = Math.floor(payout) / 10 ** toDecimals;
  const scaled_remainder = Math.floor(remainder) / 10 ** fromDecimals;

  return [scaled_payout, scaled_remainder];
};

const findTokensForBatch = (batch: Batch) => {
  const pair = batch.pair;
  const tkns = {
    to: { name: pair.name_0, decimals: parseInt(pair.decimals_0, 10) },
    from: { name: pair.name_1, decimals: parseInt(pair.decimals_1, 10) },
  };
  return tkns;
};

const wasInClearingForBatch = (
  side: 'sell' | 'buy',
  tolerance: 'minus' | 'exact' | 'plus',
  clearingTolerance: 'minus' | 'exact' | 'plus'
) => {
  const toNumber = (x: 'minus' | 'exact' | 'plus'): -1 | 0 | 1 =>
    x === 'minus' ? -1 : x === 'exact' ? 0 : 1;

  const clearingToleranceNumber = toNumber(
    clearingTolerance as 'minus' | 'exact' | 'plus'
  );
  const toleranceNumber = toNumber(tolerance as 'minus' | 'exact' | 'plus');

  if (side === 'buy') {
    return clearingToleranceNumber >= toleranceNumber;
  }
  return clearingToleranceNumber <= toleranceNumber;
};

const getSideFromDeposit = (deposit: Deposit) => {
  const rawSide = Object.keys(deposit.key.side)[0];
  if (rawSide !== 'buy' && rawSide !== 'sell')
    throw new Error('Unable to parse side.');
  return rawSide;
};

const getTolerance = (obj: {}) => {
  const rawTolerance = Object.keys(obj)[0];
  if (
    rawTolerance !== 'minus' &&
    rawTolerance !== 'exact' &&
    rawTolerance !== 'plus'
  )
    throw new Error('Unable to parse tolerance.');

  return rawTolerance;
};

const computeHoldingsByBatchAndDeposit = (
  deposit: Deposit,
  batch: Batch,
  currentHoldings: HoldingsState
) => {
  const side = getSideFromDeposit(deposit);

  const tokens = findTokensForBatch(batch);
  if (batchIsCleared(batch.status)) {
    const clearing = batch.status['cleared'].clearing;
    const clearedVolumes = {
      cleared: {
        from: parseInt(
          clearing.total_cleared_volumes.sell_side_total_cleared_volume,
          10
        ),
        to: parseInt(
          clearing.total_cleared_volumes.buy_side_total_cleared_volume,
          10
        ),
      },
      subjectToClearing: {
        from: parseInt(
          clearing.total_cleared_volumes.sell_side_volume_subject_to_clearing,
          10
        ),
        to: parseInt(
          clearing.total_cleared_volumes.buy_side_volume_subject_to_clearing,
          10
        ),
      },
    };

    if (
      !wasInClearingForBatch(
        side,
        getTolerance(deposit.key.tolerance),
        getTolerance(clearing.clearing_tolerance)
      ) ||
      clearedVolumes.cleared.to === 0 ||
      clearedVolumes.cleared.from === 0
    ) {
      return {
        ...currentHoldings,
        cleared: {
          ...currentHoldings.cleared,
          [tokens.to.name]:
            currentHoldings.cleared[tokens.to.name] +
            (side === 'buy'
              ? getDepositAmount(
                  parseInt(deposit.value, 10),
                  tokens.to.decimals
                )
              : 0),
          [tokens.from.name]:
            currentHoldings.cleared[tokens.from.name] +
            (side === 'sell'
              ? getDepositAmount(
                  parseInt(deposit.value, 10),
                  tokens.from.decimals
                )
              : 0),
        },
      };
    } else {
      if (side === 'sell') {
        const payout = convertHoldingToPayout(
          parseInt(deposit.value, 10),
          clearedVolumes.subjectToClearing.from,
          clearedVolumes.cleared.from,
          clearedVolumes.cleared.to,
          tokens.from.decimals,
          tokens.to.decimals
        );
        return {
          ...currentHoldings,
          cleared: {
            ...currentHoldings.cleared,
            [tokens.to.name]:
              currentHoldings.cleared[tokens.to.name] + payout[0],
            [tokens.from.name]:
              currentHoldings.cleared[tokens.from.name] + payout[1],
          },
        };
      }
      const payout = convertHoldingToPayout(
        parseInt(deposit.value, 10),
        clearedVolumes.subjectToClearing.to,
        clearedVolumes.cleared.to,
        clearedVolumes.cleared.from,
        tokens.to.decimals,
        tokens.from.decimals
      );
      return {
        ...currentHoldings,
        cleared: {
          ...currentHoldings.cleared,
          [tokens.to.name]: currentHoldings.cleared[tokens.to.name] + payout[1],
          [tokens.from.name]:
            currentHoldings.cleared[tokens.from.name] + payout[0],
        },
      };
    }
  } else {
    return {
      ...currentHoldings,
      open: {
        ...currentHoldings.open,
        [tokens.to.name]:
          currentHoldings.open[tokens.to.name] +
          (side === 'buy'
            ? getDepositAmount(parseInt(deposit.value, 10), tokens.to.decimals)
            : 0),
        [tokens.from.name]:
          currentHoldings.open[tokens.from.name] +
          (side === 'sell'
            ? getDepositAmount(
                parseInt(deposit.value, 10),
                tokens.from.decimals
              )
            : 0),
      },
    };
  }
};

//TODO type o1: { tzBTC: number, USDT: number }, o2:{ tzBTC: number, USDT: number }
const addObj = (o1: any, o2: any) => {
  return Object.keys(o1).reduce(
    (acc, c) => {
      return {
        ...acc,
        [c]: o1[c] + o2[c],
      };
    },
    { tzBTC: 0, USDT: 0 }
  );
};

const computeHoldingsByBatch = (
  deposits: Deposit[], //! depots dans un batch
  batch: Batch,
  currentHoldings: HoldingsState
) => {
  return deposits.reduce(
    (acc, d) => {
      return {
        open: addObj(
          acc.open,
          computeHoldingsByBatchAndDeposit(d, batch, currentHoldings).open
        ),
        cleared: addObj(
          acc.cleared,
          computeHoldingsByBatchAndDeposit(d, batch, currentHoldings).cleared
        ),
      };
    },
    { open: { tzBTC: 0, USDT: 0 }, cleared: { tzBTC: 0, USDT: 0 } }
  );
};

//TODO: improve that
export const getOrdersBook = async (address: string, userAddress: string) => {
  const storage = await getStorageByAddress(address);
  const b: { [key: number]: Deposit[] } = await getBigMapByIdAndUserAddress(
    storage['user_batch_ordertypes'],
    userAddress
  );
  return Promise.all(
    Object.entries(b).map(async ([batchNumber, deposits]) => {
      const batch = await getBigMapByIdAndBatchNumber(
        storage['batch_set']['batches'],
        parseInt(batchNumber, 10)
      );
      return computeHoldingsByBatch(deposits, batch, {
        open: { tzBTC: 0, USDT: 0 },
        cleared: { tzBTC: 0, USDT: 0 },
      });
    })
  ).then(holdings =>
    holdings.reduce(
      (acc, currentHoldings) => {
        return {
          open: addObj(acc.open, currentHoldings.open),
          cleared: addObj(acc.cleared, currentHoldings.cleared),
        };
      },
      { open: { tzBTC: 0, USDT: 0 }, cleared: { tzBTC: 0, USDT: 0 } }
    )
  );
};

const getDepositAmount = (depositAmount: number, decimals: number) =>
  Math.floor(depositAmount) / 10 ** decimals;

const getUserVault = async (
  userAddress: string,
  key: string,
  userVaultId: number,
  holdingsVaultId: number
) => {
  if (!userAddress) {
    console.info('No user address ');
    console.info(userAddress);
    const userVault: UserVault = {
      shares: 0,
      unclaimed: 0,
    };
    return userVault;
  }

  const ukey = await getBigMapByIdAndKey(userVaultId, key);
  console.info(holdingsVaultId);
  console.info(ukey);
  const h = await getBigMapByIdAndKey(holdingsVaultId, ukey);
  console.info('userVault');
  console.info(h);
  if (!h) {
    const userVault: UserVault = {
      shares: 0,
      unclaimed: 0,
    };
    return userVault;
  }
  const uv: UserVault = {
    shares: h.shares,
    unclaimed: h.unclaimed,
  };
  return uv;
};

export const getVaultFromBigMap = async (
  vaultId: number,
  token: any,
  userVaultId: number,
  userAddress: string,
  holdingsVaultId: number
): Promise<MVault> => {
  const b = await getBigMapByIdAndKey(vaultId, token.name);
  const rtk = b.native_token;
  const scaleAmount = scaleAmountDown(rtk.amount, token.decimals);
  const key: string = `{"string":"${token.name}","address":"${userAddress}"}`;
  console.info(key);
  const userVault = await getUserVault(
    userAddress,
    key,
    userVaultId,
    holdingsVaultId
  );
  const globalVault: GlobalVault = {
    total_shares: b.total_shares,
    native: {
      name: token.name,
      id: token.token_id,
      address: token.address,
      decimals: token.decimals,
      standard: token.standard,
      amount: scaleAmount,
    },
    foreign: new Map<string, VaultToken>(),
  };
  const mvault = {
    global: globalVault,
    user: userVault,
  };

  return mvault;
};

export const getMarketHoldings = async (
  marketMakerAddress: string,
  userAddress: string
) => {
  const storage = await getStorageByAddress(marketMakerAddress);
  console.log('Vaults id', storage.vaults);
  console.log('MMStorage', storage);
  const usrAddress = !userAddress
    ? 'tz1WfhZiKXiy7zVMxBzMFrdaNJ5nhPM5W2Ef'
    : userAddress;
  console.log('usrAddress', usrAddress);
  return Promise.all(
    Object.values(storage.valid_tokens).map(
      async token =>
        await getVaultFromBigMap(
          storage.vaults,
          token,
          storage.user_holdings,
          usrAddress,
          storage.vault_holdings
        )
    )
  );
};
export const getMVault = (vault: MVault | undefined) => {
  return !vault ? initialMVault : vault;
};
