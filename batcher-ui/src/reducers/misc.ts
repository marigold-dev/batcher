import { MiscActions } from 'src/actions';
// import { liftState, loop } from 'redux-loop';
// import { setupTezosToolkitCmd } from 'src/commands';
import { BatcherStatus, MiscState } from 'src/types';

// TODO: fp-ts

const initialState: MiscState = {
  settings: null,
  tezos: undefined,
  batcherStatus: BatcherStatus.STARTED,
};

const miscReducer = (state: MiscState = initialState, action: MiscActions) => {
  if (!state) return initialState;
  switch (action.type) {
    case 'UDPATE_BATCHER_STATUS':
      return { ...state, batcherStatus: action.payload.status };
    // // case 'SETUP_TEZOS_TOOLKIT':
    //   return loop(state, setupTezosToolkitCmd());
    // case 'TEZOS_TOOLKIT_SETUPED':
    // return { ...state, tezos: action.payload.tezos };
    default:
      return state;
  }
};

export default miscReducer;
