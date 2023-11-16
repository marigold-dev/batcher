import {
  add,
  differenceInMilliseconds,
  differenceInMinutes,
  parseISO,
} from 'date-fns';
import {
  BatcherStatus,
  UserOrder,
  HoldingsState,
  VolumesState,
  VolumesStorage,
  batchIsCleared,
  BatcherStorage,
  BatchBigmap,
  OrderBookBigmap,
  SwapNames,
  RatesCurrentBigmap,
  Token,
  ValidToken,
  ValidSwap,
  ValidTokenAmount,
} from '@/types';
import {
  getTokenManagerStorage,
  getTokensFromStorage,
  getSwapsFromStorage,
  getLexicographicalPairName,
} from '@/utils/token-manager';
import { NetworkType } from '@airgap/beacon-sdk';
import { getByKey } from '@/utils/local-storage';

export const getTokens = async () => {
  const tokens = await getTokensFromStorage();
  console.info('getTokens tokens', tokens);
  const tokenMap = new Map(tokens.map((value, index) => [value.name, value]));
  console.info('getTokens tokenMap', tokenMap);

  return {
    tokens: tokenMap,
  };
};

export const getSwaps = async () => {
  const swaps = await getSwapsFromStorage();
  console.info('getSwaps swaps', swaps);
  const swapsMap = new Map(
    swaps.map((value, index) => [
      getLexicographicalPairName(value.swap.to, value.swap.from),
      value,
    ])
  );
  console.info('getSwaps swapMap', swapsMap);

  return {
    swaps: swapsMap,
  };
};

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
  [100, 'no_rate_available_for_swap'],
  [101, 'invalid_token_address'],
  [102, 'invalid_tezos_address'],
  [103, 'no_open_batch'],
  [104, 'batch_should_be_cleared'],
  [105, 'trying_to_close_batch_which_is_not_open'],
  [106, 'unable_to_parse_side_from_external_order'],
  [107, 'unable_to_parse_tolerance_from_external_order'],
  [108, 'token_standard_not_found'],
  [109, 'xtz_not_currently_supported'],
  [110, 'unsupported_swap_type'],
  [111, 'unable_to_reduce_token_amount_to_less_than_zero'],
  [112, 'too_many_unredeemed_orders'],
  [113, 'insufficient_swap_fee'],
  [114, 'sender_not_administrator'],
  [115, 'token_already_exists_but_details_are_different'],
  [116, 'swap_already_exists'],
  [117, 'swap_does_not_exist'],
  [118, 'endpoint_does_not_accept_tez'],
  [119, 'number_is_not_a_nat'],
  [120, 'oracle_price_is_stale'],
  [121, 'oracle_price_is_not_timely'],
  [122, 'unable_to_get_price_from_oracle'],
  [123, 'unable_to_get_price_from_new_oracle_source'],
  [124, 'oracle_price_should_be_available_before_deposit'],
  [125, 'swap_is_disabled_for_deposits'],
  [126, 'upper_limit_on_tokens_has_been_reached'],
  [127, 'upper_limit_on_swap_pairs_has_been_reached'],
  [128, 'cannot_reduce_limit_on_tokens_to_less_than_already_exists'],
  [129, 'cannot_reduce_limit_on_swap_pairs_to_less_than_already_exists'],
  [130, 'more_tez_sent_than_fee_cost'],
  [131, 'cannot_update_deposit_window_to_less_than_the_minimum'],
  [132, 'cannot_update_deposit_window_to_more_than_the_maximum'],
  [133, 'oracle_must_be_equal_to_minimum_precision'],
  [134, 'swap_precision_is_less_than_minimum'],
  [135, 'cannot_update_scale_factor_to_less_than_the_minimum'],
  [136, 'cannot_update_scale_factor_to_more_than_the_maximum'],
  [137, 'cannot_remove_swap_pair_that_is_not_disabled'],
  [138, 'token_name_not_in_list_of_valid_tokens'],
  [139, 'no_orders_for_user_address'],
  [140, 'cannot_cancel_orders_for_a_batch_that_is_not_open'],
  [141, 'cannot_decrease_holdings_of_removed_batch'],
  [142, 'cannot_increase_holdings_of_batch_that_does_not_exist'],
  [143, 'batch_already_removed'],
  [144, 'admin_and_fee_recipient_address_cannot_be_the_same'],
  [145, 'incorrect_market_vault_holder'],
  [146, 'incorrect_market_vault_id'],
  [147, 'market_vault_tokens_are_different'],
  [148, 'unable_to_find_user_holding_for_id'],
  [149, 'unable_to_find_vault_holding_for_id'],
  [150, 'user_in_holding_is_incorrect'],
  [151, 'no_holding_in_market_maker_for_holder'],
  [152, 'no_market_vault_for_token'],
  [153, 'holding_amount_to_redeem_is_larger_than_holding'],
  [154, 'holding_shares_greater_than_total_shares_remaining'],
  [155, 'no_holdings_to_claim'],
  [156, 'incorrect_side_specified'],
  [157, 'entrypoint_does_not_exist'],
  [158, 'unable_to_get_batches_from_batcher'],
  [159, 'unable_to_get_oracle_price'],
  [160, 'contract_does_not_exist'],
  [161, 'unable_to_call_on_chain_view'],
  [162, 'unable_to_get_tokens_from_token_manager'],
  [163, 'vault_name_is_incorrect'],
  [164, 'unable_to_get_native_token_from_vault'],
  [165, 'unable_to_get_swaps_from_token_manager'],
  [166, 'unable_to_get_vaults_from_marketmaker'],
  [167, 'unable_to_get_current_batches_from_batcher'],
  [168, 'sender_not_marketmaker'],
  [169, 'cannot_update_liquidity_injection_limit_to_more_than_deposit_window'],
  [170, 'unable_to_get_balance_response_fa2_entrypoint_from_vault'],
  [171, 'unable_to_get_balance_of_entrypoint_from_fa2_token'],
  [172, 'unable_to_get_balance_response_fa12_entrypoint_from_vault'],
  [173, 'unable_to_get_get_balance_entrypoint_from_fa12_token'],
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

export type Balance = {
  name: string;
  balance: number;
  decimals: number;
};

export type Balances = Balance[];

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

export const checkStatus = (
  response: Response,
  noContentReturnValue?: unknown
) => {
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
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/tokens/balances?account=${userAddress}`
  ).then(checkStatus);

export const getBalances = async (userAddress: string): Promise<Balances> => {
  const tokenManagerStorage = await getTokenManagerStorage();
  const validTokens = tokenManagerStorage['valid_tokens'];
  const rawBalances = await getTokensBalancesByAccount(userAddress);
  console.info('DEBUG: storage', tokenManagerStorage);
  let bals = new Array<Balance>();
  for await (const token_name of validTokens.keys) {
    const token = await getBigMapByIdAndKey(validTokens.values, token_name);
    console.info('DEBUG: token', token);
    const balance = rawBalances.find(
      (b: TokenBalance) => b.token?.contract?.address === token.address
    )?.balance;
    const decimals = parseInt(token.decimals, 10);
    const bal: Balance = {
      name: token.name,
      decimals,
      balance: balance ? scaleAmountDown(parseFloat(balance), decimals) : 0,
    };
    bals.push(bal);
  }
  return bals;
};

// ----- FETCH STORAGE AND BIGMAPS ------

export const getStorage = (): Promise<BatcherStorage> =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/contracts/${process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH}/storage`
  ).then(checkStatus);

export const getBigMapByIdAndUserAddress = (
  userAddress?: string
): Promise<OrderBookBigmap> => {
  const bigMapId: string | null = getByKey('user_batch_ordertypes');
  if (!userAddress || !bigMapId)
    return Promise.reject('No address or no bigmap ID for order book.');
  return (
    fetch(
      `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigMapId}/keys/${userAddress}`
    )
      // TODO: improve that by parseStatus function
      .then(response => checkStatus(response, { value: [] }))
      .then(r => r.value)
  );
};

export const getBigMapByIdAndKey = async (
  id: number,
  key: string
): Promise<any> => {
  if (!id) return Promise.reject('No bigmap ID .');
  if (!key) return Promise.reject('No key for bigmap .');
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${id}/keys/${key}`
  )
    .then(checkStatus)
    .then(r => r.value);
};

export const getBigMapByIdAndBatchNumber = async (
  batchNumber: number
): Promise<BatchBigmap> => {
  const bigMapId: string | null = getByKey('batches');
  if (!bigMapId) return Promise.reject('No bigmap ID for batches.');
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigMapId}/keys/${batchNumber}`
  )
    .then(checkStatus)
    .then(r => r.value);
};

export const getBigMapByIdAndTokenPair = async (
  tokenPair: string
): Promise<Array<RatesCurrentBigmap>> => {
  const bigMapId: string | null = getByKey('rates_current');
  if (!bigMapId) return Promise.reject('No bigmap ID for rates_current.');

  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigMapId}/keys`
  )
    .then(checkStatus)
    .then(response =>
      response.filter((r: any) => r.key === tokenPair).map((r: any) => r.value)
    );
};

// ----- FETCH CONTRACT INFORMATIONS AND PARSING ------

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

export const ensureMapTypeOnTokens = (
  tokens: Map<string, Token>
): Map<string, Token> => {
  const typeOfTokens = typeof tokens;
  console.info('tokens type', typeOfTokens);
  if (tokens instanceof Map) {
    return tokens;
  } else {
    let toks: Map<string, Token> = new Map<string, Token>();
    Object.values(tokens).forEach(v => {
      console.info('v', v);
      toks = v as Map<string, Token>;
    });
    return toks;
  }
};

export const ensureMapTypeOnSwaps = (
  swaps: Map<string, ValidSwap>
): Map<string, ValidSwap> => {
  const typeOfSwaps = typeof swaps;
  console.info('swaps type', typeOfSwaps);
  if (swaps instanceof Map) {
    return swaps;
  } else {
    let swps: Map<string, ValidSwap> = new Map<string, ValidSwap>();
    Object.values(swaps).forEach(v => {
      console.info('v', v);
      swps = v as Map<string, ValidSwap>;
    });
    return swps;
  }
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

export const getVolumes = async (
  batchNumber: number,
  tokens: Map<string, Token>
) => {
  const batch = await getBigMapByIdAndBatchNumber(batchNumber);
  const buyTokenName = batch.pair.string_0;
  const sellTokenName = batch.pair.string_1;
  const toks = Object.values(tokens)[0];
  const buyToken = toks.get(buyTokenName);
  const sellToken = toks.get(sellTokenName);
  return toVolumes(batch['volumes'], {
    buyDecimals: parseInt(buyToken.decimals, 10),
    sellDecimals: parseInt(sellToken.decimals, 10),
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

const findTokensForBatch = (batch: BatchBigmap, toks: Map<string, Token>) => {
  const pair = batch.pair;
  console.info('TOKS', toks);
  const tokens = ensureMapTypeOnTokens(toks);
  console.info('TOKENS', tokens);
  const buyToken = tokens.get(pair.string_0);
  const sellToken = tokens.get(pair.string_1);
  const tkns = {
    to: { name: buyToken?.name || '', decimals: buyToken?.decimals || 0 },
    from: { name: sellToken?.name || '', decimals: sellToken?.decimals || 0 },
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
  currentHoldings: HoldingsState,
  tokenMap: Map<string, Token>
) => {
  const side = getSideFromDeposit(deposit);
  const tokens = findTokensForBatch(batch, tokenMap);

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
  tokens: Map<string, Token>,
  deposits: UserOrder[], //! depots dans un batch
  batch: BatchBigmap,
  currentHoldings: HoldingsState
) => {
  return deposits.reduce(
    (acc, d) => {
      return {
        open: addObj(
          acc.open,
          computeHoldingsByBatchAndDeposit(d, batch, currentHoldings, tokens)
            .open
        ),
        cleared: addObj(
          acc.cleared,
          computeHoldingsByBatchAndDeposit(d, batch, currentHoldings, tokens)
            .cleared
        ),
      };
    },
    {
      open: { tzBTC: 0, USDT: 0, EURL: 0 },
      cleared: { tzBTC: 0, USDT: 0, EURL: 0 },
    }
  );
};

export const computeAllHoldings = async (
  orderbook: OrderBookBigmap,
  tokens: Map<string, Token>
) => {
  return Promise.all(
    Object.entries(orderbook).map(async ([batchNumber, deposits]) => {
      const batch = await getBigMapByIdAndBatchNumber(
        parseInt(batchNumber, 10)
      );
      return computeHoldingsByBatch(tokens, deposits, batch, {
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

export const getOrdersBook = async (
  userAddress: string,
  tokens: Map<string, Token>
) => {
  const orderBookByBatch: { [key: number]: UserOrder[] } =
    await getBigMapByIdAndUserAddress(userAddress);
  return computeAllHoldings(orderBookByBatch, tokens);
};

const getDepositAmount = (depositAmount: number, decimals: number) =>
  Math.floor(depositAmount) / 10 ** decimals;

export const emptyToken = () => {
  const t: Token = {
    address: '',
    name: '',
    decimals: 0,
    standard: 'FA2 token',
    tokenId: 0,
  };
  return t;
};

export const emptyValidToken = () => {
  const t: ValidToken = {
    name: '',
    address: '',
    token_id: '0',
    decimals: '0',
    standard: '',
  };
  return t;
};

export const emptyValidTokenAmount = () => {
  const ta: ValidTokenAmount = {
    token: emptyValidToken(),
    amount: 0,
  };
  return ta;
};
