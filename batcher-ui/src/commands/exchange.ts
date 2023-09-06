import { Cmd } from 'redux-loop';
import {
  computeOraclePrice,
  getBatcherStatus,
  fetchCurrentBatchNumber,
  getCurrentRates,
  getPairsInformations,
  getVolumes,
  getTimeDifferenceInMs,
} from '../utils/utils';
import {
  updateBatchNumber,
  updateBatcherStatus,
  updatePairsInfos,
  updateOraclePrice,
  updateVolumes,
  batcherTimerId,
  updateRemainingTime,
  noBatchError,
} from '../actions';
import { BatcherStatus, CurrentSwap, SwapNames } from 'src/types';

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
      failActionCreator: (e: string) => noBatchError(e),
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

const setupBatcherCmd = (startTime: string | null, status: BatcherStatus) => {
  if (startTime && status === BatcherStatus.OPEN) {
    return Cmd.list([
      Cmd.setTimeout(
        Cmd.action(
          updateBatcherStatus({
            status: BatcherStatus.CLOSED,
            at: startTime,
            startTime,
          })
        ),
        getTimeDifferenceInMs(status, startTime)
      ),
      Cmd.setInterval(Cmd.action(updateRemainingTime()), 10000, {
        scheduledActionCreator: timerId => batcherTimerId(timerId),
      }),
    ]);
  }
  return Cmd.none;
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
