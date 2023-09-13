import { BigMapEvent } from 'src/types/events';

export const newEvent = (event: BigMapEvent) =>
  ({
    type: 'NEW_EVENT',
    payload: { event },
  } as const);

  export const closeToast = () =>
    ({
      type: 'CLOSE_TOAST',
    } as const);

  export const newError = (errorContent: string) =>
    ({
      type: 'NEW_ERROR',
      payload: { errorContent },
    } as const);

  export const newInfo = (infoContent: string) =>
    ({
      type: 'NEW_INFO',
      payload: { infoContent },
    } as const);

  export type EventActions =
    | ReturnType<typeof newEvent>
    | ReturnType<typeof newError>
    | ReturnType<typeof newInfo>
    | ReturnType<typeof closeToast>;
