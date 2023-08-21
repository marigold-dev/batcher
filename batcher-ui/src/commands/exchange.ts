import { Cmd } from 'redux-loop';
import {
  computeOraclePrice,
  getBatcherStatus,
  getCurrentBatchNumber,
  getCurrentRates,
  getPairsInformations,
  getVolumes,
} from '../../utils/utils';
import {
  updateBatchNumber,
  updateBatcherStatus,
  updatePairsInfos,
  getCurrentBatchNumber as getCurrentBatchNumberAction,
  getPairsInfos,
  updateOraclePrice,
  updateVolumes,
  batcherTimerId,
} from '../actions';
import { CurrentSwap } from 'src/types';

const fetchPairInfosCmd = (pair: string) =>
  Cmd.run(
    () => {
      return getPairsInformations(
        pair,
        process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH || ''
      );
    },
    {
      successActionCreator: updatePairsInfos,
    }
  );

const fetchCurrentBatchNumberCmd = (pair: string) =>
  Cmd.run(
    () => {
      return getCurrentBatchNumber(
        process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH || '',
        pair
      );
    },
    {
      successActionCreator: updateBatchNumber,
    }
  );

const fetchBatcherStatusCmd = (batchNumber: number) =>
  Cmd.run(
    () => {
      return getBatcherStatus(
        batchNumber,
        process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH || ''
      );
    },
    {
      successActionCreator: updateBatcherStatus,
    }
  );

const setupBatcherCmd = (pair: string) => {
  return Cmd.list([
    Cmd.action(getCurrentBatchNumberAction()),
    Cmd.action(getPairsInfos(pair)),
    Cmd.setInterval(Cmd.action(getCurrentBatchNumberAction()), 50000, {
      scheduledActionCreator: timerId => batcherTimerId(timerId),
    }),
  ]);
};

const getOraclePriceCmd = (tokenPair: string, currentSwap: CurrentSwap) => {
  return Cmd.run(
    () => {
      return getCurrentRates(
        tokenPair,
        process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH || ''
      ).then(rates => computeOraclePrice(rates[0], currentSwap));
    },
    {
      successActionCreator: updateOraclePrice,
    }
  );
};

const fetchVolumesCmd = (batchNumber: number, currentSwap: CurrentSwap) => {
  return Cmd.run(
    () => {
      return getVolumes(
        batchNumber,
        currentSwap,
        process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH || ''
      );
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
  getOraclePriceCmd,
  fetchVolumesCmd,
};
