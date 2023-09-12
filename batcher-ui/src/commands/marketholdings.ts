import { Cmd } from 'redux-loop';
import { getMarketHoldings } from '../utils/utils';
import { updateMarketHoldings } from 'src/actions/marketholdings';

const fetchMarketHoldingsCmd = (userAddress?: string) => {
  return Cmd.run(
    async () => {
      const marketHoldings = await getMarketHoldings(
        process.env.NEXT_PUBLIC_MARKETMAKER_CONTRACT_HASH || '',
        userAddress
      );

      return marketHoldings;
    },
    {
      successActionCreator: updateMarketHoldings,
    }
  );
};

export { fetchMarketHoldingsCmd };
