import { Cmd } from 'redux-loop';
import {
  computeOraclePrice,
  getBatcherStatus,
  fetchCurrentBatchNumber,
  getCurrentRates,
  getPairsInformations,
  getVolumes,
} from '../utils/utils';
import {
  updateBatchNumber,
  updateBatcherStatus,
  updatePairsInfos,
  updateOraclePrice,
  updateVolumes,
  batcherTimerId,
  getBatcherStatus as getBatcherStatusAction,
} from '../actions';
import { CurrentSwap, SwapNames } from 'src/types';

const fetchPairInfosCmd = (pair: string) =>
  Cmd.run(
    () => {
      return getPairsInformations(pair);
    },
    {
      successActionCreator: updatePairsInfos,
    }
  );

const fetchCurrentBatchNumberCmd = (pair: SwapNames) =>
  Cmd.run(
    () => {
      return fetchCurrentBatchNumber(pair);
    },
    {
      successActionCreator: updateBatchNumber,
    }
  );

const fetchBatcherStatusCmd = (batchNumber: number) =>
  Cmd.run(
    () => {
      return getBatcherStatus(batchNumber);
    },
    {
      successActionCreator: updateBatcherStatus,
    }
  );

//TODO: setup timeout to close batch when started + 10min
const setupBatcherCmd = (pair: string) => {
  return Cmd.setInterval(Cmd.action(getBatcherStatusAction()), 50000, {
    scheduledActionCreator: timerId => batcherTimerId(timerId),
  });
};

const fetchOraclePriceCmd = (tokenPair: string, { swap }: CurrentSwap) => {
  return Cmd.run(
    async () => {
      const rates = await getCurrentRates(tokenPair);
      return computeOraclePrice(rates[0].rate, {
        buyDecimals: swap.to.decimals,
        sellDecimals: swap.from.token.decimals,
      });
    },
    {
      successActionCreator: updateOraclePrice,
    }
  );
};

const fetchVolumesCmd = (batchNumber: number) => {
  return Cmd.run(
    () => {
      return getVolumes(batchNumber);
    },
    {
      successActionCreator: updateVolumes,
    }
  );
};

export {
  fetchPairInfosCmd,
  fetchCurrentBatchNumberCmd,
  fetchBatcherStatusCmd,
  setupBatcherCmd,
  fetchOraclePriceCmd,
  fetchVolumesCmd,
};
