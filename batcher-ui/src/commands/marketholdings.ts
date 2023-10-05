import { Cmd } from 'redux-loop';
import { getMarketHoldings } from '../utils/utils';
import { MarketHoldingsState } from '../types/state';
import { updateMarketHoldings } from 'src/actions';

const fetchMarketHoldingsCmd = (
  contractAddress: string,
  userAddress: string
) => {
  return Cmd.run(
    async () => {
      // const usrAddress = !userAddress
      //   ? 'tz1WfhZiKXiy7zVMxBzMFrdaNJ5nhPM5W2Ef'
      //   : userAddress;
      const vaultArray: Array<Record<string, any>> = await getMarketHoldings(
        contractAddress,
        userAddress || ''
      );
      console.log('🚀 ~ file: marketholdings.ts:19 ~ vaultArray:', vaultArray);
      // const vaults = new Map(vaultArray.map(i => [i.global.native.name, i]));
      // console.info('vaults');
      // console.info(vaults);
      // const firstVault = vaults.values().next().value;
      const ms: MarketHoldingsState = {
        globalVaults: vaultArray.map(v => Object.values(v)[0]),
        // current_vault: firstVault,
      };
      console.log('🚀 ~ file: marketholdings.ts:28 ~ ms:', ms);
      return ms;
    },
    {
      successActionCreator: updateMarketHoldings,
    }
  );
};

export { fetchMarketHoldingsCmd };
