import { BigMapEvent } from 'src/types/events';

export const newEvent = (event: BigMapEvent) =>
  ({
    type: 'NEW_EVENT',
    payload: { event },
  } as const);

export type EventActions = ReturnType<typeof newEvent>;
