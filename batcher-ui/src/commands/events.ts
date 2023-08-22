import { Cmd } from 'redux-loop';
import {
  updateBatchNumber,
  getBatcherStatus,
  updateVolumes,
  updateOraclePrice,
} from 'src/actions';
import { currentSwapSelector } from 'src/reducers';
import { AddBatchEvent, BigMapEvent, UpdateRateEvent } from 'src/types/events';
import { computeOraclePrice, toVolumes } from 'utils/utils';

export const newEventCmd = (event: BigMapEvent) => {
  return Cmd.run(
    (dispatch, getState) => {
      return event.data.map(eventData => {
        switch (eventData.action) {
          case 'add_key': {
            if (eventData.path === 'batch_set.batches') {
              const data = eventData.content.value as AddBatchEvent;
              // new batch
              dispatch(updateBatchNumber(data.batch_number));
              dispatch(getBatcherStatus());
              //TODO:
              // dispatch(updateBatcherStatus(data.status));
              dispatch(
                updateVolumes(
                  toVolumes(data.volumes, {
                    buyDecimals: parseInt(data.pair.decimals_1, 10),
                    sellDecimals: parseInt(data.pair.decimals_0, 10),
                  })
                )
              );
              return Promise.resolve();
            }
            return Promise.reject('Unknown event');
          }
          case 'update_key': {
            if (eventData.path === 'rates_current') {
              const data = eventData.content.value as UpdateRateEvent;
              const { swap } = currentSwapSelector(getState());
              dispatch(
                updateOraclePrice(
                  computeOraclePrice(data.rate, {
                    buyDecimals: swap.to.decimals,
                    sellDecimals: swap.from.token.decimals,
                  })
                )
              );
              return Promise.resolve();
            }
            if (eventData.path === 'batch_set.batches') {
              console.log('🚀 ~ file: events.ts:67 ~ eventData:', eventData);
              dispatch(getBatcherStatus());
              return Promise.resolve();
            }
            return Promise.reject('Unknown event');
          }
          default:
            return Promise.reject('Unknown event');
        }
      });
    },
    {
      args: [Cmd.dispatch, Cmd.getState],
    }
  );
};
