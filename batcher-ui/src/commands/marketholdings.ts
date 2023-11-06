import { Cmd } from 'redux-loop';
import { getMarketHoldings } from '@/utils/market-maker';
import { updateMarketHoldings } from '@/actions';

const fetchMarketHoldingsCmd = (token: string, userAddress: string | undefined) => {
  return Cmd.run(
    async () => {
      const vaults = await getMarketHoldings(token, userAddress || '');
      return vaults;
    },
    {
      successActionCreator: updateMarketHoldings,
    }
  );
};

export { fetchMarketHoldingsCmd };
