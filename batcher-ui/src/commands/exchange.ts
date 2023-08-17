import { Cmd } from 'redux-loop';
import {
  getBatcherStatus,
  getCurrentBatchNumber,
  getPairsInformations,
} from '../../utils/utils';
import {
  updateBatchNumber,
  updateBatcherStatus,
  updatePairsInfos,
  getCurrentBatchNumber as getCurrentBatchNumberAction,
} from '../actions';

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
  return Cmd.setInterval(Cmd.action(getCurrentBatchNumberAction()), 30000);
};

export {
  fetchPairInfosCmd,
  fetchCurrentBatchNumberCmd,
  fetchBatcherStatusCmd,
  setupBatcherCmd,
};
