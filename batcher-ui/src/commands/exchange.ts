import { Cmd } from 'redux-loop';
import {
  computeOraclePrice,
  getBatcherStatus,
  fetchCurrentBatchNumber,
  getCurrentRates,
  getVolumes,
  getTimeDifferenceInMs,
  getTokens,
  getSwaps,
  ensureMapTypeOnTokens,
} from '@/utils/utils';
import { getPairsInformation, getTokensMetadata } from '@/utils/token-manager';
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
  updateSwaps,
  updateDisplayTokens,
} from '@/actions';
import {
  BatcherStatus,
  CurrentSwap,
  SwapNames,
  Token,
  ValidSwap,
  ExchangeState,
  DisplayToken,
} from '@/types';

const fetchPairInfosCmd = (state: ExchangeState, pair: string) =>
  Cmd.run(
    () => {
      return getPairsInformation(pair, state.currentSwap);
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

const fetchOraclePriceCmd = (
  tokenPair: string,
  tokens: Map<string, Token>,
  { swap }: CurrentSwap
) => {
  return Cmd.run(
    async () => {
      console.info('TokenPair', tokenPair);
      const rates = await getCurrentRates(tokenPair);
      console.info('Rates', rates);
      const rate = rates[0];
      const tokensMapped = ensureMapTypeOnTokens(tokens);
      const to = tokensMapped.get(rate.swap.to);
      const from = tokensMapped.get(rate.swap.from);
      return computeOraclePrice(rate.rate, {
        buyDecimals: to.decimals,
        sellDecimals: from.decimals,
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
      const mapped: Map<string, Token> = tokens as unknown as Map<
        string,
        Token
      >;
      console.info('Mapped tokens', mapped);
      return mapped;
    },
    {
      successActionCreator: updateTokens,
      failActionCreator: (e: string) => newError(e),
    }
  );
};

const fetchSwapsCmd = () => {
  return Cmd.run(
    async () => {
      const swaps = await getSwaps();
      const mapped: Map<string, ValidSwap> = swaps as unknown as Map<
        string,
        ValidSwap
      >;
      console.info('Mapped swaps', mapped);
      return mapped;
    },
    {
      successActionCreator: updateSwaps,
      failActionCreator: (e: string) => newError(e),
    }
  );
};

const fetchDisplayTokensCmd = () => {
  return Cmd.run(
    async () => {
      const tokensMetadata = await getTokensMetadata();

      const mapped: Map<string, DisplayToken> =
        tokensMetadata as unknown as Map<string, DisplayToken>;
      console.info('Mapped tokens', mapped);
      return mapped;
    },
    {
      successActionCreator: updateDisplayTokens,
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
  fetchSwapsCmd,
  fetchDisplayTokensCmd,
};
