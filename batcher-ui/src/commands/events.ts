import { Cmd } from 'redux-loop';
import {
  updateBatchNumber,
  updateVolumes,
  updateOraclePrice,
  updateBatcherStatus,
} from '@/actions';
import { updateHoldings } from '@/actions/holdings';
import { userAddressSelector } from '@/reducers';
import type {
  BatchBigmap,
  OrderBookBigmap,
  RatesCurrentBigmap,
  BigMapEvent,
} from '@/types';
import {
  computeAllHoldings,
  computeOraclePrice,
  mapStatus,
  toVolumes,
} from '@/utils/utils';

export const newEventCmd = (event: BigMapEvent) => {
  return Cmd.run(
    (dispatch, getState) => {
      return event.data.map(async eventData => {
        switch (eventData.action) {
          case 'add_key': {
            switch (eventData.path) {
              case 'batch_set.batches': {
                const data = eventData.content.value as BatchBigmap;
                const status = mapStatus(data);
                //! new batch
                dispatch(updateBatchNumber(parseInt(data.batch_number)));
                dispatch(updateBatcherStatus(status));
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
              case 'user_batch_ordertypes': {
                //! deposit from new address
                const data = eventData.content.value as OrderBookBigmap;
                const userAddress = userAddressSelector(getState());
                //! user addresses are keys of this bigmap so we need to ensure that the key is the user address
                if (userAddress === eventData.content.key) {
                  const holdings = await computeAllHoldings(data);
                  dispatch(updateHoldings(holdings));
                }
                return Promise.resolve();
              }
              case 'rates_current':
              default:
                return Promise.reject('Unknown event');
            }
          }
          case 'update_key': {
            switch (eventData.path) {
              case 'rates_current': {
                //! oracle price has changed
                const data = eventData.content.value as RatesCurrentBigmap;
                console.info("Oracle change",data);
                dispatch(
                  updateOraclePrice(
                    computeOraclePrice(data.rate, {
                      buyDecimals: parseInt(data.swap.to.decimals),
                      sellDecimals: parseInt(data.swap.from.token.decimals),
                    })
                  )
                );
                return Promise.resolve();
              }
              case 'batch_set.batches': {
                //! batch status has changed
                const data = eventData.content.value as BatchBigmap;
                const status = mapStatus(data);
                dispatch(updateBatcherStatus(status));
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
              case 'user_batch_ordertypes': {
                //! new deposit or redeem from an existing address
                const data = eventData.content.value as OrderBookBigmap;
                const userAddress = userAddressSelector(getState());
                //! user addresses are keys of this bigmap so we need to ensure that the key is the user address
                if (userAddress === eventData.content.key) {
                  const holdings = await computeAllHoldings(data);
                  dispatch(updateHoldings(holdings));
                }
                return Promise.resolve();
              }
              default:
                return Promise.reject('Unknown event');
            }
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
