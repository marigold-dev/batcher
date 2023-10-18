import { Cmd } from 'redux-loop';
import {
  getGlobalVault,
  getMarketHoldings,
  getUserVault2,
} from '@/utils/market-maker';
import {
  updateGlobalVault,
  updateMarketHoldings,
  updateUserVault,
} from '@/actions';

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

const fetchUserVaultCmd = (userAddress: string, tokenName: string) => {
  return Cmd.run(
    async () => {
      const userVault = await getUserVault2(userAddress, tokenName);
      return userVault;
    },
    {
      successActionCreator: updateUserVault,
    }
  );
};

const fetchGlobalVaultCmd = (tokenName: string) => {
  return Cmd.run(
    async () => {
      const globalVault = await getGlobalVault(tokenName);

      return globalVault;
    },
    {
      successActionCreator: updateGlobalVault,
    }
  );
};

export { fetchMarketHoldingsCmd, fetchUserVaultCmd, fetchGlobalVaultCmd };
