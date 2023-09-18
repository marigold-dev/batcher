import { Cmd } from 'redux-loop';
import { getMarketHoldings } from '../utils/utils';
import { MarketHoldingsState, initialMVault } from '../types/state';
import { updateMarketHoldings } from 'src/actions/marketholdings';

const switchVaultCmd = (state: MarketHoldingsState, vault?: string) => {
  return Cmd.run(
    () => {
      if (!vault) {
        console.info('switch vault');
        console.info(vault);
        return state;
      }

      const v = state.vaults.get(vault);
      console.info('v');
      console.info(v);
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
  contractAddress: string,
  userAddress: string
) => {
  return Cmd.run(
    async () => {
  const usrAddress = !userAddress
    ? 'tz1WfhZiKXiy7zVMxBzMFrdaNJ5nhPM5W2Ef'
    : userAddress;
      const vaultArray = await getMarketHoldings(contractAddress, usrAddress);
      const vaults = new Map(vaultArray.map(i => [i.global.native.name, i]));
      console.info('vaults');
      console.info(vaults);
      const firstVault = vaults.values().next().value;
      const ms: MarketHoldingsState = {
        vaults: vaults,
        current_vault: firstVault,
      };
      return ms;
    },
    {
      successActionCreator: updateMarketHoldings,
    }
  );
};

export { fetchMarketHoldingsCmd, switchVaultCmd };
