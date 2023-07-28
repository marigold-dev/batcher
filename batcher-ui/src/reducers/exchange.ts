import { ExchangeActions } from 'src/actions';
import { CurrentSwap, ExchangeState, PriceStrategy } from 'src/types';

const initialSwap: CurrentSwap = {
  swapPairName: 'tzBTC/USDT',
  swap: {
    from: {
      token: {
        token_id: 0,
        name: 'tzBTC',
        address: undefined,
        decimals: 0,
        standard: 'FA1.2 token',
      },
      amount: 0,
    },
    to: {
      token_id: 0,
      name: 'USDT',
      address: undefined,
      decimals: 0,
      standard: 'FA2 token',
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
