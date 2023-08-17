import { Cmd, loop } from 'redux-loop';
import { ExchangeActions, getPairsInfos } from '../../src/actions';
import { CurrentSwap, ExchangeState, PriceStrategy } from '../../src/types';
import { fetchPairInfosCmd } from '../../src/commands/exchange';

const initialSwap: CurrentSwap = {
  swapPairName: 'tzBTC/USDT',
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
};

const exchangeReducer = (
  state: ExchangeState = initialState,
  action: ExchangeActions
) => {
  if (!state) return initialState;
  switch (action.type) {
    case 'CHANGE_PAIR':
      return loop(state, Cmd.action(getPairsInfos(action.payload.pair)));
    case 'GET_PAIR_INFOS':
      return loop(state, fetchPairInfosCmd(action.payload.pair));
    case 'UPDATE_PAIR_INFOS': {
      return {
        ...state,
        currentSwap: {
          ...action.payload.currentSwap,
        },
      };
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
    default:
      return state;
  }
};

export default exchangeReducer;
