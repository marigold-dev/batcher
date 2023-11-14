import { Cmd } from 'redux-loop';
import { getOrdersBook } from '@/utils/utils';
import { updateHoldings } from '@/actions/holdings';
import { newError } from '@/actions';

const fetchHoldingsCmd = (tokens: any, userAddress?: string) => {
  return Cmd.run(
    async () => {
      if (!userAddress) return Promise.reject('Not connected !');
      const holdings = await getOrdersBook(userAddress, tokens);
      console.info('holdings', holdings);
      return holdings;
    },
    {
      successActionCreator: updateHoldings,
      failActionCreator: (e: string) => newError(e),
    }
  );
};

export { fetchHoldingsCmd };
