import { Cmd, loop } from 'redux-loop';
import {
  ExchangeActions,
  getBatcherStatus,
  getCurrentBatchNumber,
  getPairsInfos,
  getVolumes,
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
  getOraclePriceCmd,
  setupBatcherCmd,
} from '../../src/commands/exchange';
import { getTimeDifference } from 'src/utils/utils';

const initialSwap: CurrentSwap = {
  swap: {
    from: {
      token: {
        token_id: 0,
        name: 'tzBTC',
        address: undefined,
        decimals: 0,
        standard: undefined,
      },
      amount: 0,
    },
    to: {
      token_id: 0,
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
      return loop(state, setupBatcherCmd(state.swapPairName));
    case 'BATCHER_TIMER_ID':
      return { ...state, batcherTimerId: action.payload.timerId };
    case 'BATCHER_UNSETUP':
      return loop(state, Cmd.clearInterval(state.batcherTimerId));
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
                  token_id: 0,
                },
              },
              to: {
                ...action.payload.currentSwap.swap.to,
                token_id: 0,
              },
            },
          },
        },
        Cmd.list([Cmd.action(getCurrentBatchNumber())])
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
      return {
        ...state,
        batcherStatus: {
          ...action.payload,
          startTime,
          remainingTime: getTimeDifference(action.payload.status, startTime),
        },
      };
    }
    case 'GET_CURRENT_BATCHER_NUMBER':
      return loop(state, fetchCurrentBatchNumberCmd(state.swapPairName));
    case 'UDPATE_BATCH_NUMBER':
      return loop(
        {
          ...state,
          batchNumber: action.payload.batchNumber,
          batcherStatus: !action.payload.batchNumber && {
            status: BatcherStatus.NONE,
            remainingTime: 0,
            startTime: null,
          },
        },
        action.payload.batchNumber
          ? Cmd.list([Cmd.action(getBatcherStatus()), Cmd.action(getVolumes())])
          : Cmd.none
      );
    case 'GET_ORACLE_PRICE':
      return loop(
        state,
        getOraclePriceCmd(state.swapPairName, state.currentSwap)
      );
    case 'UPDATE_ORACLE_PRICE':
      return { ...state, oraclePrice: action.payload.oraclePrice };
    case 'GET_VOLUMES':
      return loop(state, fetchVolumesCmd(state.batchNumber, state.currentSwap));
    case 'UPDATE_VOLUMES':
      return { ...state, volumes: action.payload.volumes };
    default:
      return state;
  }
};

export default exchangeReducer;
