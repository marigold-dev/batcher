import { Cmd } from 'redux-loop';
import { scaleAmountDown, storeBalances } from '../../utils/utils';
import { gotUserBalances } from '../actions';
import * as api from '@tzkt/sdk-api';

const fetchUserBalancesCmd = (userAddress?: string) => {
  return Cmd.run(
    async () => {
      if (!userAddress) return Promise.reject('No address !');
      const rawBalances = await api.tokensGetTokenBalances({
        account: {
          eq: userAddress,
        },
      });
      console.log(
        '🚀 ~ file: wallet.ts:138 ~ returnCmd.run ~ rawBalances:',
        rawBalances
      );
      console.log(
        '🚀 ~ file: wallet.ts:134 ~ returnCmd.run ~ rawBalances:',
        storeBalances(rawBalances)
      );

      return storeBalances(rawBalances).map(b => ({
        ...b,
        balance: scaleAmountDown(b.balance, b.decimals),
      }));
    },
    {
      successActionCreator: gotUserBalances,
    }
  );
};

export { fetchUserBalancesCmd };
