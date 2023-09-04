import { Cmd } from 'redux-loop';
import { getBalances } from '../utils/utils';
import { gotUserBalances } from '../actions';

const fetchUserBalancesCmd = (userAddress?: string) => {
  return Cmd.run(
    async () => {
      if (!userAddress) return Promise.reject('No address !');

      return getBalances(
        process.env.NEXT_PUBLIC_BATCHER_CONTRACT_HASH || '',
        userAddress
      );
    },
    {
      successActionCreator: gotUserBalances,
    }
  );
};

export { fetchUserBalancesCmd };
