import { Cmd } from 'redux-loop';
import { getMarketHoldings } from '../utils/utils';
import { MarketHoldingsState, initialMVault } from '../types/state';
import { updateMarketHoldings } from 'src/actions/marketholdings';

const switchVaultCmd = (state: MarketHoldingsState, vault?: string) => {
  return Cmd.run(
    () => {
      if (!vault) {
        return state;
      }

      const v = state.vaults.get(vault);
      if (!v) {
        return state;
      }

      const ms: MarketHoldingsState = {
        ...state,
        current_vault: v,
      };
      return ms;
    },
    {
      successActionCreator: updateMarketHoldings,
    }
  );
};

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
        current_vault: initialMVault,
      };
      return ms;
    },
    {
      successActionCreator: updateMarketHoldings,
    }
  );
};

export { fetchMarketHoldingsCmd, switchVaultCmd };
