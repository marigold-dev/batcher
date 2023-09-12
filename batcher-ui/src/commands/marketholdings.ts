import { Cmd } from 'redux-loop';
import { getMarketHoldings } from '../utils/utils';
import { MarketHoldingsState } from '../types/state';
import { updateMarketHoldings } from 'src/actions/marketholdings';

const fetchMarketHoldingsCmd = (
  contractAddress?: string,
  userAddress?: string
) => {
  return Cmd.run(
    async () => {
      const vaultArray = await getMarketHoldings(
        contractAddress || '',
        userAddress || ''
      );
      const vaults = new Map(vaultArray.map(i => [i.global.native.name, i]));

      const ms: MarketHoldingsState = {
        vaults: vaults,
      };
      return ms;
    },
    {
      successActionCreator: updateMarketHoldings,
    }
  );
};

export { fetchMarketHoldingsCmd };
