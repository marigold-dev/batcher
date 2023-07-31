import { MiscActions } from 'src/actions';
import { BatcherStatus, MiscState } from 'src/types';

const initialState: MiscState = {
  settings: null,
  batcherStatus: BatcherStatus.STARTED,
};

const miscReducer = (state: MiscState = initialState, action: MiscActions) => {
  if (!state) return initialState;
  switch (action.type) {
    case 'UDPATE_BATCHER_STATUS':
      return { ...state, batcherStatus: action.payload.status };
    default:
      return state;
  }
};

export default miscReducer;
