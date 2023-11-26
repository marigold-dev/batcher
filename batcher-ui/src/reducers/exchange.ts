import { Cmd, loop } from 'redux-loop';
import {
  ExchangeActions,
  batcherUnsetup,
  getCurrentBatchNumber,
  getOraclePrice,
  getPairsInfos,
} from '@/actions';
import {
  BatcherStatus,
  CurrentSwap,
  ExchangeState,
  PriceStrategy,
  Token,
  ValidSwap,
  DisplayToken,
} from '@/types';
import {
  fetchBatcherStatusCmd,
  fetchCurrentBatchNumberCmd,
  fetchPairInfosCmd,
  fetchVolumesCmd,
  fetchOraclePriceCmd,
  setupBatcherCmd,
  fetchTokensCmd,
  fetchSwapsCmd,
  fetchDisplayTokensCmd,
} from '@/commands/exchange';
import {
  getTimeDifference,
  ensureMapTypeOnSwaps,
  ensureMapTypeOnTokens,
} from 'src/utils/utils';

const initialSwap: CurrentSwap = {
  swap: {
    from: {
      tokenId: 0,
      name: 'tzBTC',
      address: undefined,
      decimals: 0,
      standard: undefined,
    },
    to: {
      tokenId: 0,
      name: 'USDT',
      address: undefined,
      decimals: 0,
      standard: undefined,
    },
  },
  isReverse: false,
};

const initialState: ExchangeState = {
  priceStrategy: PriceStrategy.EXACT,
  currentSwap: initialSwap,
  batcherTimerId: 0,
  batcherStatus: {
    status: BatcherStatus.NONE,
    at: null,
    startTime: null,
    remainingTime: 0,
  },
  swapPairName: 'tzBTC-USDT',
  batchNumber: 0,
  oraclePrice: 0,
  oraclePair: 'tzBTC-USDT',
  tokens: new Map<string, Token>(),
  swaps: new Map<string, ValidSwap>(),
  displayTokens: new Map<string, DisplayToken>(),
  volumes: {
    sell: Object.keys(PriceStrategy).reduce(
      (acc, k) => ({ ...acc, [k]: 0 }),
      {}
    ) as Record<PriceStrategy, number>,
    buy: Object.keys(PriceStrategy).reduce(
      (acc, k) => ({ ...acc, [k]: 0 }),
      {}
    ) as Record<PriceStrategy, number>,
  },
};

const getSwapFromSwaps = (state: ExchangeState, pair: string) => {
  if (pair === undefined || pair === null || pair === '') {
    console.error('pair is undefined for swap');
    return initialSwap;
  } else {
    const mappedSwaps = ensureMapTypeOnSwaps(state.swaps);
    const mappedTokens = ensureMapTypeOnTokens(state.tokens);
    console.info('@@@@@@ pair', pair);
    const swap = mappedSwaps.get(pair);
    if (!swap) {
      return initialSwap;
    } else {
      console.info('@@@@@@', swap);
      const to = mappedTokens.get(swap.swap.to);
      const from = mappedTokens.get(swap.swap.from);
      console.info('@@@@@@ to', to);
      console.info('@@@@@@ from', from);
      const currentSwap = {
        from: from,
        to: to,
      };
      console.info('@@@@ current swap', currentSwap);
      return {
        ...state.currentSwap,
        swap: currentSwap,
      };
    }
  }
};

const exchangeReducer = (
  state: ExchangeState = initialState,
  action: ExchangeActions
) => {
  if (!state) return initialState;
  switch (action.type) {
    case 'BATCHER_SETUP':
      return loop(
        state,
        setupBatcherCmd(
          state.batcherStatus.startTime,
          state.batcherStatus.status
        )
      );
    case 'BATCHER_TIMER_ID':
      return { ...state, batcherTimerId: action.payload.timerId };
    case 'BATCHER_UNSETUP':
      return loop(state, Cmd.clearTimeout(state.batcherTimerId));
    case 'CHANGE_PAIR':
      return loop(
        {
          ...state,
          swapPairName: action.payload.pair,
          currentSwap: getSwapFromSwaps(state, action.payload.pair),
        },
        Cmd.action(getPairsInfos(action.payload.pair))
      );
    case 'GET_PAIR_INFOS':
      return loop(state, fetchPairInfosCmd(state, action.payload.pair));
    case 'UPDATE_PAIR_INFOS': {
      //! We hard code token_id because it's not in contract storage.
      //! Update this when we use token with token_id != 0
      return loop(
        {
          ...state,
          swapPairName: action.payload.pair,
          currentSwap: !action.payload.currentSwap
            ? state.currentSwap.swap
            : action.payload.currentSwap,
        },
        Cmd.list([
          Cmd.action(getOraclePrice()),
          Cmd.action(getCurrentBatchNumber()),
        ])
      );
    }
    case 'UDPATE_PRICE_STATEGY':
      return {
        ...state,
        priceStrategy: action.payload.priceStrategy,
      };
    case 'REVERSE_SWAP':
      return {
        ...state,
        currentSwap: {
          ...state.currentSwap,
          isReverse: !state.currentSwap.isReverse,
        },
      };
    case 'GET_BATCHER_STATUS':
      return loop(state, fetchBatcherStatusCmd(state.batchNumber));
    case 'UDPATE_BATCHER_STATUS': {
      const startTime =
        action.payload.startTime || state.batcherStatus.startTime;
      return loop(
        {
          ...state,
          batcherStatus: {
            ...action.payload,
            startTime,
            remainingTime: getTimeDifference(action.payload.status, startTime),
          },
        },
        action.payload.status === BatcherStatus.CLOSED
          ? Cmd.action(batcherUnsetup())
          : Cmd.none
      );
    }
    case 'UPDATE_REMAINING_TIME':
      return {
        ...state,
        batcherStatus: {
          ...state.batcherStatus,
          remainingTime: getTimeDifference(
            state.batcherStatus.status,
            state.batcherStatus.startTime
          ),
        },
      };
    case 'GET_CURRENT_BATCHER_NUMBER':
      return loop(state, fetchCurrentBatchNumberCmd(state.swapPairName));
    case 'UDPATE_BATCH_NUMBER':
      return loop(
        {
          ...state,
          batchNumber: action.payload.batchNumber,
        },
        fetchBatcherStatusCmd(action.payload.batchNumber)
      );
    case 'GET_ORACLE_PRICE':
      return loop(
        state,
        fetchOraclePriceCmd(state.swapPairName, state.tokens,state.currentSwap)
      );
    case 'UPDATE_ORACLE_PRICE':
      return { ...state, oraclePrice: action.payload.oraclePrice };
    case 'GET_VOLUMES':
      return loop(state, fetchVolumesCmd(state.batchNumber, state.tokens));
    case 'UPDATE_VOLUMES':
      return { ...state, volumes: action.payload.volumes };
    case 'UPDATE_TOKENS':
      console.info('tokens', action.payload.tokens);
      console.info('state', state);
      return { ...state, tokens: action.payload.tokens };
    case 'GET_TOKENS':
      return loop(state, fetchTokensCmd());
    case 'UPDATE_SWAPS':
      console.info('swaps', action.payload.swaps);
      console.info('state', state);
      return { ...state, swaps: action.payload.swaps };
    case 'GET_SWAPS':
      return loop(state, fetchSwapsCmd());
    case 'UPDATE_DISPLAY_TOKENS':
      console.info('display_tokens', action.payload.display_tokens);
      console.info('state', state);
      return { ...state, displayTokens: action.payload.display_tokens };
    case 'GET_DISPLAY_TOKENS':
      return loop(state, fetchDisplayTokensCmd());
    default:
      return state;
  }
};

export default exchangeReducer;
