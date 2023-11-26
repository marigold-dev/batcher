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
  Token,
} from '@/types';
import {
  computeAllHoldings,
  computeOraclePrice,
  mapStatus,
  toVolumes,
  ensureMapTypeOnTokens,
} from '@/utils/utils';

export const newEventCmd = (event: BigMapEvent, toks: Map<string, Token>) => {
  const tokens = ensureMapTypeOnTokens(toks);
  return Cmd.run(
    (dispatch, getState) => {
      return event.data.map(async eventData => {
        switch (eventData.action) {
          case 'add_key': {
            switch (eventData.path) {
              case 'batch_set.batches': {
                const data = eventData.content.value as BatchBigmap;
                const status = mapStatus(data);
                //const toks = Object.values(tokens)[0];
                const buyToken = tokens.get(data.pair.string_0);
                const sellToken = tokens.get(data.pair.string_1);
                //! new batch
                dispatch(updateBatchNumber(parseInt(data.batch_number)));
                dispatch(updateBatcherStatus(status));
                dispatch(
                  updateVolumes(
                    toVolumes(data.volumes, {
                      buyDecimals: buyToken?.decimals || 0,
                      sellDecimals: sellToken?.decimals || 0,
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
                  const holdings = await computeAllHoldings(data, tokens);
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
                console.info('Oracle change', data);
                const buyToken = tokens.get(data.swap.from.token.name);
                const sellToken = tokens.get(data.swap.to.name);
                const buyTokenDecimals: number = buyToken?.decimals || 0;
                const sellTokenDecimals: number = sellToken?.decimals || 0;
                dispatch(
                  updateOraclePrice(
                    computeOraclePrice(data.rate, {
                      buyDecimals: buyTokenDecimals,
                      sellDecimals: sellTokenDecimals,
                    })
                  )
                );
                return Promise.resolve();
              }
              case 'batch_set.batches': {
                //! batch status has changed
                const data = eventData.content.value as BatchBigmap;
                const status = mapStatus(data);
                const buyToken = tokens.get(data.pair.string_0);
                const sellToken = tokens.get(data.pair.string_1);
                const buyTokenDecimals: number = buyToken?.decimals || 0;
                const sellTokenDecimals: number = sellToken?.decimals || 0;
                dispatch(updateBatcherStatus(status));
                dispatch(
                  updateVolumes(
                    toVolumes(data.volumes, {
                      buyDecimals: buyTokenDecimals,
                      sellDecimals: sellTokenDecimals,
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
                  const holdings = await computeAllHoldings(data, tokens);
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
