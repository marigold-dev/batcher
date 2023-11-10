import { Cmd, loop } from 'redux-loop';
import {
  ExchangeActions,
  batcherUnsetup,
  getCurrentBatchNumber,
  getOraclePrice,
  getPairsInfos,
} from '../../src/actions';
import {
  BatcherStatus,
  CurrentSwap,
  ExchangeState,
  PriceStrategy,
} from '../../src/types';
import {
  fetchBatcherStatusCmd,
  fetchCurrentBatchNumberCmd,
  fetchPairInfosCmd,
  fetchVolumesCmd,
  fetchOraclePriceCmd,
  setupBatcherCmd,
} from '../../src/commands/exchange';
import { getTimeDifference } from 'src/utils/utils';

const initialSwap: CurrentSwap = {
  swap: {
    from: {
      token: {
        tokenId: 0,
        name: 'tzBTC',
        address: undefined,
        decimals: 0,
        standard: undefined,
      },
      amount: 0,
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
  swapPairName: 'tzBTC/USDT',
  batchNumber: 0,
  oraclePrice: 0,
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
          currentSwap: {
            ...state.currentSwap,
            isReverse: action.payload.isReverse,
          },
        },
        Cmd.action(getPairsInfos(action.payload.pair))
      );
    case 'GET_PAIR_INFOS':
      return loop(state, fetchPairInfosCmd(action.payload.pair));
    case 'UPDATE_PAIR_INFOS': {
      //! We hard code token_id because it's not in contract storage.
      //! Update this when we use token with token_id != 0
      return loop(
        {
          ...state,
          swapPairName: action.payload.pair,
          currentSwap: {
            ...action.payload.currentSwap,
            isReverse: state.currentSwap.isReverse,
            swap: {
              from: {
                token: {
                  ...action.payload.currentSwap.swap.from.token,
                  tokenId: 0,
                },
              },
              to: {
                ...action.payload.currentSwap.swap.to,
                tokenId: 0,
              },
            },
          },
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
        fetchOraclePriceCmd(state.swapPairName, state.currentSwap)
      );
    case 'UPDATE_ORACLE_PRICE':
      return { ...state, oraclePrice: action.payload.oraclePrice };
    case 'GET_VOLUMES':
      return loop(state, fetchVolumesCmd(state.batchNumber));
    case 'UPDATE_VOLUMES':
      return { ...state, volumes: action.payload.volumes };
   /* case 'NO_BATCH_ERROR':    //TODO - No batch being open isn't an error - the first deposit will open a batch
      return loop(
        {
          ...state,
          batcherStatus: {
            status: BatcherStatus.NONE,
            at: null,
            startTime: null,
            remainingTime: 0,
          },
          batchNumber: 0,
        },
        Cmd.action(newError('No batch open for this pair.'))
      ); */
    default:
      return state;
  }
};

export default exchangeReducer;
