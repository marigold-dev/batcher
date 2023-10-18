import { loop } from 'redux-loop';
import { EventActions } from '@/actions/events';
import { newEventCmd } from '@/commands/events';
import { EventsState } from '@/types';

const initialState: EventsState = {
  toast: {
    isToastOpen: false,
    toastDescription: '',
    type: 'error',
  },
};

export const eventReducer = (
  state: EventsState = initialState,
  action: EventActions
) => {
  switch (action.type) {
    case 'NEW_EVENT':
      return loop(state, newEventCmd(action.payload.event));
    case 'NEW_INFO':
      return {
        ...state,
        toast: {
          isToastOpen: true,
          toastDescription: action.payload.infoContent,
          type: 'info',
        },
      };
    case 'NEW_ERROR':
      return {
        ...state,
        toast: {
          isToastOpen: true,
          toastDescription: action.payload.errorContent,
          type: 'error',
        },
      };
    case 'CLOSE_TOAST':
      return initialState;
    default:
      return state;
  }
};
