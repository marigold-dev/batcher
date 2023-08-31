import { Cmd } from 'redux-loop';
import { getOrdersBook } from '../../utils/utils';
import { updateHoldings } from 'src/actions/holdings';

const fetchHoldingsCmd = (userAddress?: string) => {
  return Cmd.run(
    async () => {
      if (!userAddress) return Promise.reject('No address !');
      const holdings = await getOrdersBook(
        process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH || '',
        userAddress
      );

      return holdings;
    },
    {
      successActionCreator: updateHoldings,
    }
  );
};

export { fetchHoldingsCmd };