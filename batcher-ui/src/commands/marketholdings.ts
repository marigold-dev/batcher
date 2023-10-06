import { Cmd } from 'redux-loop';
import { getMarketHoldings } from '../utils/utils';
import { updateMarketHoldings } from 'src/actions';

const fetchMarketHoldingsCmd = (
  contractAddress: string,
  userAddress: string
) => {
  return Cmd.run(
    async () => {
      const vaults = await getMarketHoldings(userAddress || '');

      return vaults;
    },
    {
      successActionCreator: updateMarketHoldings,
    }
  );
};

export { fetchMarketHoldingsCmd };
