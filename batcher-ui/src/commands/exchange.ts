import { Cmd } from 'redux-loop';
import {
  computeOraclePrice,
  getBatcherStatus,
  getCurrentBatchNumber,
  getCurrentRates,
  getPairsInformations,
} from '../../utils/utils';
import {
  updateBatchNumber,
  updateBatcherStatus,
  updatePairsInfos,
  getCurrentBatchNumber as getCurrentBatchNumberAction,
  getPairsInfos,
  updateOraclePrice,
} from '../actions';
import { CurrentSwap } from 'src/types';

const fetchPairInfosCmd = (pair: string) =>
  Cmd.run(
    () => {
      return getPairsInformations(
        pair,
        process.env.REACT_APP_BATCHER_CONTRACT_HASH || ''
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
        process.env.REACT_APP_BATCHER_CONTRACT_HASH || '',
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
        process.env.REACT_APP_BATCHER_CONTRACT_HASH || ''
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
    Cmd.setInterval(Cmd.action(getCurrentBatchNumberAction()), 50000),
  ]);
};

const getOraclePriceCmd = (tokenPair: string, currentSwap: CurrentSwap) => {
  return Cmd.run(
    () => {
      return getCurrentRates(
        tokenPair,
        process.env.REACT_APP_BATCHER_CONTRACT_HASH || ''
      ).then(rates => computeOraclePrice(rates[0], currentSwap));
    },
    {
      successActionCreator: updateOraclePrice,
    }
  );
};

export {
  fetchPairInfosCmd,
  fetchCurrentBatchNumberCmd,
  fetchBatcherStatusCmd,
  setupBatcherCmd,
  getOraclePriceCmd,
};
