import {
  add,
  differenceInMilliseconds,
  differenceInMinutes,
  parseISO,
} from 'date-fns';
import {
  BatcherStatus,
  CurrentSwap,
  UserOrder,
  HoldingsState,
  VolumesState,
  VolumesStorage,
  batchIsCleared,
  BatcherStorage,
  BatchBigmap,
  OrderBookBigmap,
  TokenNames,
  SwapNames,
  RatesCurrentBigmap,
  UserVault,
  GlobalVault,
  VaultToken,
  BatcherMarketMakerStorage,
  UserHoldingsBigMapItem,
  VaultsBigMapItem,
  VaultHoldingsBigMapItem,
  ContractToken,
} from '../types';
import { NetworkType } from '@airgap/beacon-sdk';
import { getByKey } from './local-storage';

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

type TokenBalance = {
  address: string;
  balance: string;
  token: {
    contract: { address: string };
    standard: string;
    tokenId: string;
    metadata: {
      name: string;
      symbol: string;
      decimals: string;
      thumbnailUri: string;
    };
  };
};

const checkStatus = (response: Response, noContentReturnValue?: unknown) => {
  if (!response.ok) return Promise.reject('FETCH_ERROR');
  if (response.status === 204) {
    //! No content
    return Promise.resolve(noContentReturnValue);
  }
  return response.json();
};

// TODO: need to configure token available in Batcher
export const TOKENS = ['USDT', 'EURL', 'TZBTC'];

export const getTokensBalancesByAccount = (userAddress: string) =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/tokens/balances?account=${userAddress}`
  ).then(checkStatus);

export const getBalances = async (userAddress: string): Promise<Balances> => {
  const storage = await getStorage();
  const validTokens: BatcherStorage['valid_tokens'] = storage['valid_tokens'];
  const rawBalances = await getTokensBalancesByAccount(userAddress);

  return Object.values(validTokens).map(token => {
    const balance = rawBalances.find(
      (b: TokenBalance) => b.token?.contract?.address === token.address
    )?.balance;
    const decimals = parseInt(token.decimals, 10);
    return {
      name: token.name,
      decimals,
      balance: balance ? scaleAmountDown(parseFloat(balance), decimals) : 0,
    };
  });
};

// ----- FETCH STORAGE AND BIGMAPS ------

export const getStorage = (): Promise<BatcherStorage> =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/contracts/${process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH}/storage`
  ).then(checkStatus);

export const getBigMapByIdAndUserAddress = (
  userAddress?: string
): Promise<OrderBookBigmap> => {
  const bigMapId: string | null = getByKey('user_batch_ordertypes');
  if (!userAddress || !bigMapId)
    return Promise.reject('No address or no bigmap ID for order book.');
  return (
    fetch(
      `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigMapId}/keys/${userAddress}`
    )
      // TODO: improve that by parseStatus function
      .then(response => checkStatus(response, { value: [] }))
      .then(r => r.value)
  );
};

export const getBigMapByIdAndBatchNumber = (
  batchNumber: number
): Promise<BatchBigmap> => {
  const bigMapId: string | null = getByKey('batches');
  if (!bigMapId) return Promise.reject('No bigmap ID for batches.');
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigMapId}/keys/${batchNumber}`
  )
    .then(checkStatus)
    .then(r => r.value);
};

export const getBigMapByIdAndTokenPair = (
  tokenPair: string
): Promise<Array<RatesCurrentBigmap>> => {
  const bigMapId: string | null = getByKey('rates_current');
  if (!bigMapId) return Promise.reject('No bigmap ID for rates_current.');

  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigMapId}/keys`
  )
    .then(checkStatus)
    .then(response =>
      response.filter((r: any) => r.key === tokenPair).map((r: any) => r.value)
    );
};

export const getTokensMetadata = async () => {
  const storage = await getStorage();
  const validTokens = storage['valid_tokens'];
  return Promise.all(
    Object.values(validTokens).map(async token => {
      const icon = await fetch(
        `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/tokens?contract=${token.address}`
      )
        .then(t => t.json())
        .then(([t]) =>
          t?.metadata?.thumbnailUri
            ? `https://ipfs.io/ipfs/${t.metadata.thumbnailUri.split('//')[1]}`
            : undefined
        );

      return {
        name: token.name,
        address: token.address,
        icon,
      };
    })
  );
};

// ----- FETCH CONTRACT INFORMATIONS AND PARSING ------

export const getPairsInformations = async (
  pair: string
): Promise<{ currentSwap: Omit<CurrentSwap, 'isReverse'>; pair: string }> => {
  const storage = await getStorage();
  const validTokens = storage['valid_tokens'];
  const pairs = pair.split('/') as TokenNames[];

  return {
    currentSwap: {
      swap: {
        from: {
          token: {
            ...validTokens[pairs[0]],
            decimals: parseInt(validTokens[pairs[0]].decimals, 10),
            tokenId: 0, //! HARD CODED
          },
          amount: 0,
        },
        to: {
          ...validTokens[pairs[1]],
          decimals: parseInt(validTokens[pairs[1]].decimals, 10),
          tokenId: 0, //! HARD CODED
        },
      },
    },
    pair,
  };
};

export const getFees = async () => {
  const storage = await getStorage();
  const feeInMutez: number = storage['fee_in_mutez'];
  return feeInMutez;
};

export const fetchCurrentBatchNumber = async (
  pair: SwapNames
): Promise<number> => {
  const storage = await getStorage();
  const currentBatchIndices = storage['batch_set']['current_batch_indices'];
  if (!currentBatchIndices || !currentBatchIndices[pair]) {
    return Promise.reject('No batch for this pair.');
  }
  return parseInt(currentBatchIndices[pair], 10);
};

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
  batchNumber: number
): Promise<{ status: BatcherStatus; at: string; startTime: string | null }> => {
  const batch = await getBigMapByIdAndBatchNumber(batchNumber);
  return mapStatus(batch);
};

export const mapStatus = (batch: BatchBigmap) => {
  const s = Object.keys(batch.status)[0];
  return {
    status: toBatcherStatus(s),
    at: new Date(getStatusTime(s, batch)).toISOString(),
    startTime: getStartTime(s, batch)
      ? new Date(getStartTime(s, batch)).toISOString()
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

export const getTimeDifferenceInMs = (
  status: BatcherStatus,
  startTime: string | null
) => {
  if (status === BatcherStatus.OPEN && startTime) {
    const now = new Date();
    const open = parseISO(startTime);
    const batcherClose = add(open, { minutes: 10 });
    const diff = differenceInMilliseconds(batcherClose, now);
    return diff < 0 ? 0 : diff;
  }
  return 0;
};

export const getCurrentRates = async (tokenPair: string) =>
  await getBigMapByIdAndTokenPair(tokenPair);

export const computeOraclePrice = (
  rate: { p: string; q: string },
  { buyDecimals, sellDecimals }: { buyDecimals: number; sellDecimals: number }
) => {
  const numerator = parseInt(rate.p);
  const denominator = parseInt(rate.q);
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

export const getVolumes = async (batchNumber: number) => {
  const batch = await getBigMapByIdAndBatchNumber(batchNumber);
  return toVolumes(batch['volumes'], {
    buyDecimals: parseInt(batch.pair.decimals_0, 10),
    sellDecimals: parseInt(batch.pair.decimals_1, 10),
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

const findTokensForBatch = (batch: BatchBigmap) => {
  const pair = batch.pair;
  const tkns = {
    // buy_token_name: pair.name_0,
    // sell_token_name: pair.name_1,
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

const getSideFromDeposit = (deposit: UserOrder) => {
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
  deposit: UserOrder,
  batch: BatchBigmap,
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
    { tzBTC: 0, USDT: 0, EURL: 0 }
  );
};

const computeHoldingsByBatch = (
  deposits: UserOrder[], //! depots dans un batch
  batch: BatchBigmap,
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
    {
      open: { tzBTC: 0, USDT: 0, EURL: 0 },
      cleared: { tzBTC: 0, USDT: 0, EURL: 0 },
    }
  );
};

export const computeAllHoldings = (orderbook: OrderBookBigmap) => {
  return Promise.all(
    Object.entries(orderbook).map(async ([batchNumber, deposits]) => {
      const batch = await getBigMapByIdAndBatchNumber(
        parseInt(batchNumber, 10)
      );
      return computeHoldingsByBatch(deposits, batch, {
        open: { tzBTC: 0, USDT: 0, EURL: 0 },
        cleared: { tzBTC: 0, USDT: 0, EURL: 0 },
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
      {
        open: { tzBTC: 0, USDT: 0, EURL: 0 },
        cleared: { tzBTC: 0, USDT: 0, EURL: 0 },
      }
    )
  );
};

export const getOrdersBook = async (userAddress: string) => {
  const orderBookByBatch: { [key: number]: UserOrder[] } =
    await getBigMapByIdAndUserAddress(userAddress);
  return computeAllHoldings(orderBookByBatch);
};

const getDepositAmount = (depositAmount: number, decimals: number) =>
  Math.floor(depositAmount) / 10 ** decimals;

// MARKET MAKER HOLDINGS

const getMarketMakerStorage = (): Promise<BatcherMarketMakerStorage> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/contracts/${process.env.NEXT_PUBLIC_MARKETMAKER_CONTRACT_HASH}/storage`
  ).then(checkStatus);
};

const getUserVaultFromBigmap = (
  bigmapId: number,
  userKey: string
): Promise<UserHoldingsBigMapItem> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigmapId}/keys/${userKey}`
  ).then(checkStatus);
};

const getHoldingsVaultFromBigmap = (
  bigmapId: number,
  key: string
): Promise<VaultHoldingsBigMapItem> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigmapId}/keys/${key}`
  ).then(checkStatus);
};
const getVaultsFromBigmap = (
  bigmapId: number,
  tokenName: string
): Promise<VaultsBigMapItem> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_URI_API}/v1/bigmaps/${bigmapId}/keys/${tokenName}`
  ).then(checkStatus);
};

const getUserVault = async (
  userAddress: string,
  key: string,
  userVaultId: number,
  holdingsVaultId: number
) => {
  console.warn('🚀 ~ file: utils.ts:730 ~ userAddress:', userAddress);
  if (!userAddress) {
    console.error('No user address ');
    const userVault: UserVault = {
      shares: 0,
      unclaimed: 0,
    };
    return userVault;
  }

  const userHoldings = await getUserVaultFromBigmap(userVaultId, key);
  if (!userHoldings) {
    console.error('No user vault ');
    const userVault: UserVault = {
      shares: 0,
      unclaimed: 0,
    };
    return userVault;
  }
  const holdingsVault = await getHoldingsVaultFromBigmap(
    holdingsVaultId,
    userHoldings.value
  );
  if (!holdingsVault || !holdingsVault.active) {
    console.error('No holding vault ');
    const userVault: UserVault = {
      shares: 0,
      unclaimed: 0,
    };
    return userVault;
  }
  const uv: UserVault = {
    shares: parseInt(holdingsVault.value.shares, 10),
    unclaimed: parseInt(holdingsVault.value.unclaimed, 10),
  };
  return uv;
};


export const getMarketHoldings = async (userAddress: string) => {
  const storage = await getMarketMakerStorage();
  const userVaults = await Promise.all(
    Object.keys(storage.valid_tokens).map(async token => {
      const userVaultKey: string = `{"string":"${token}","address":"${userAddress}"}`;
      const userVault = await getUserVault(
        userAddress,
        userVaultKey,
        storage.user_holdings,
        storage.vault_holdings
      );
      return {
        [token]: userVault,
      };
    })
  );

  const y = userVaults.reduce((acc, v) => {
    const name = Object.keys(v)[0];
    return { ...acc, [name]: v[name] };
  }, {});

  const globalVaults = await Promise.all(
    Object.keys(storage.valid_tokens).map(async token => {
      const t = storage.valid_tokens[token] as ContractToken & {
        token_id: number;
      };
      const b = await getVaultsFromBigmap(storage.vaults, token);
      const rtk = b.value.native_token;

      const scaleAmount = scaleAmountDown(
        parseInt(rtk.amount, 10),
        parseInt(t.decimals, 10)
      );
      const globalVault: GlobalVault = {
        total_shares: parseInt(b.value.total_shares, 10),
        native: {
          name: t.name,
          id: t.token_id,
          address: t.address,
          decimals: parseInt(t.decimals, 10),
          standard: t.standard,
          amount: scaleAmount,
        },
        foreign: new Map<string, VaultToken>(),
      };
      return { [token]: globalVault };
    })
  );

  const x = globalVaults.reduce((acc, v) => {
    const name = Object.keys(v)[0];
    return { ...acc, [name]: v[name] };
  }, {});
  return { globalVaults: x, userVaults: y };
};
