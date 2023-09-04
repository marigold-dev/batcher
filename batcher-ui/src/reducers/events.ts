import { loop } from 'redux-loop';
import { EventActions } from 'src/actions/events';
import { newEventCmd } from 'src/commands/events';

export const eventReducer = (state: {} = {}, action: EventActions) => {
  switch (action.type) {
    case 'NEW_EVENT':
      return loop(state, newEventCmd(action.payload.event));
    default:
      return state;
  }
};
