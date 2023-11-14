import { Cmd } from 'redux-loop';
import {
  computeOraclePrice,
  getBatcherStatus,
  fetchCurrentBatchNumber,
  getCurrentRates,
  getVolumes,
  getTimeDifferenceInMs,
  getTokens,
} from '@/utils/utils';
import { getPairsInformation } from '@/utils/token-manager';
import {
  updateBatchNumber,
  updateBatcherStatus,
  updatePairsInfos,
  updateOraclePrice,
  updateVolumes,
  batcherTimerId,
  updateRemainingTime,
  newError,
  updateTokens,
} from '@/actions';
import { BatcherStatus, CurrentSwap, SwapNames, Token } from '@/types';

const fetchPairInfosCmd = (pair: string) =>
  Cmd.run(
    () => {
      return getPairsInformation(pair);
    },
    {
      successActionCreator: updatePairsInfos,
      failActionCreator: (e: any) =>
        newError('Fail to get pair informations.' + e),
    }
  );

const fetchCurrentBatchNumberCmd = (pair: SwapNames) =>
  Cmd.run(
    () => {
      return fetchCurrentBatchNumber(pair);
    },
    {
      successActionCreator: updateBatchNumber,
      //failActionCreator: (e: string) => noBatchError(e),
    }
  );

const fetchBatcherStatusCmd = (batchNumber: number) =>
  Cmd.run(
    () => {
      return getBatcherStatus(batchNumber);
    },
    {
      successActionCreator: updateBatcherStatus,
      // failActionCreator: () => newError('Fail to get batch status.'),
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
      Cmd.setInterval(Cmd.action(updateRemainingTime()), 60000, {
        scheduledActionCreator: timerId => batcherTimerId(timerId),
      }),
    ]);
  }
  return Cmd.none;
};

const fetchOraclePriceCmd = (tokenPair: string, { swap }: CurrentSwap) => {
  return Cmd.run(
    async () => {
      console.info('TokenPair', tokenPair);
      const rates = await getCurrentRates(tokenPair);
      console.info('Rates', rates);
      return computeOraclePrice(rates[0].rate, {
        buyDecimals: swap.to.decimals,
        sellDecimals: swap.from.token.decimals,
      });
    },
    {
      successActionCreator: updateOraclePrice,
      failActionCreator: () => newError('Fail to get oracle price.'),
    }
  );
};

const fetchVolumesCmd = (batchNumber: number, tokens: Map<string, Token>) => {
  return Cmd.run(
    () => {
      return getVolumes(batchNumber, tokens);
    },
    {
      successActionCreator: updateVolumes,
      failActionCreator: () => newError('Fail to fetch batch volumes.'),
    }
  );
};

const fetchTokensCmd = () => {
  return Cmd.run(
    async () => {
      const tokens = await getTokens();
      const mapped: Map<string, Token> = ((tokens as unknown) as Map<string, Token>);
      console.info('Mapped tokens', mapped);
      return mapped;
    },
    {
      successActionCreator: updateTokens,
      failActionCreator: (e: string) => newError(e),
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
  fetchTokensCmd,
};
