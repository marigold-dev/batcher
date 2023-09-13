import { Cmd } from 'redux-loop';
import { getOrdersBook } from '../utils/utils';
import { updateHoldings } from 'src/actions/holdings';
import { newError } from 'src/actions';

const fetchHoldingsCmd = (userAddress?: string) => {
  return Cmd.run(
    async () => {
      if (!userAddress) return Promise.reject('Not connected !');
      const holdings = await getOrdersBook(userAddress);

      return holdings;
    },
    {
      successActionCreator: updateHoldings,
      failActionCreator: (e: string) => newError(e),
    }
  );
};

export { fetchHoldingsCmd };
