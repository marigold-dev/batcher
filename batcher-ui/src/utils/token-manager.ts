import {
  TokenManagerStorage,
  ValidTokensBigmapItem,
  ValidSwapsBigmapItem,
  CurrentSwap,
  ValidToken,
  ValidTokenAmount,
} from '@/types';
import { checkStatus, scaleAmountDown } from '@/utils/utils';

export const getTokenManagerStorage = (): Promise<TokenManagerStorage> =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/contracts/${process.env.NEXT_PUBLIC_TOKEN_MANAGER_CONTRACT_HASH}/storage`
  ).then(checkStatus);

const getTokenFromBigmap = (
  bigMapId: number,
  tokenName: string
): Promise<ValidTokensBigmapItem> =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigMapId}/keys/${tokenName}`
  ).then(checkStatus);

const getSwapFromBigmap = (
  bigMapId: number,
  swapName: string
): Promise<ValidSwapsBigmapItem> =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigMapId}/keys/${swapName}`
  ).then(checkStatus);

export const getLexicographicalPairName = (
  to: string,
  from: string
): string => {
  const comp = to.localeCompare(from);
  if (comp < 0)
    return `${to}-${from}`;
  } else {
    return `${from}-${to}`;
  }
};

export const getSwapsMetadata = async () => {
  const storage = await getTokenManagerStorage();
  const validSwaps = storage['valid_swaps'];
  const names = validSwaps.keys;
  return Promise.all(
    names.map(async swap => {
      const escapedPair = encodeURIComponent(swap);
      const t = await getSwapFromBigmap(validSwaps.values, escapedPair);
      const swapname = getLexicographicalPairName(
        t.value.swap.to,
        t.value.swap.from
      );
      return {
        name: swapname,
        to: t.value.swap.to,
        from: t.value.swap.from,
      };
    })
  );
};

export const parseStandard = (standard: string) => {
  if (standard == 'FA2 token') {
    return standard as 'FA2 token';
  }

  if (standard == 'FA1.2 token') {
    return standard as 'FA1.2 token';
  }

  return undefined;
};

export const getPairsInformation = async (
  pair: string
): Promise<{ currentSwap: Omit<CurrentSwap, 'isReverse'>; pair: string }> => {
  const storage = await getTokenManagerStorage();
  //const validSwaps = storage['valid_swaps']; //TODO - Only swaps pairs allowed by the contract should be displayed. A token might not be swappable with every other token
  const validTokens = storage['valid_tokens'];
  const pairs = pair.split('-');
  const left = (await getTokenFromBigmap(validTokens.values, pairs[0])).value;
  const right = (await getTokenFromBigmap(validTokens.values, pairs[1])).value;

  return {
    currentSwap: {
      swap: {
        from: {
          token: {
            ...left,
            decimals: parseInt(left.decimals),
            tokenId: parseInt(left.token_id),
            standard: parseStandard(left.standard),
          },
          amount: 0,
        },
        to: {
          ...right,
          decimals: parseInt(right.decimals),
          tokenId: parseInt(right.token_id),
          standard: parseStandard(right.standard),
        },
      },
    },
    pair,
  };
};

export const parseToken = (tokenObject: any): ValidToken => {
  try {
    return {
      name: tokenObject.name,
      address: tokenObject.address,
      token_id: tokenObject.token_id,
      decimals: tokenObject.decimals,
      standard: tokenObject.standard,
    };
  } catch (e: any) {
    console.error('Unable to parse valid token', e);
    return {
      name: '',
      address: '',
      token_id: '0',
      decimals: '0',
      standard: '',
    };
  }
};

export const parseTokenAmount = (tokenAmountObject: any): ValidTokenAmount => {
  try {
    const scaledAmount = scaleAmountDown(
      parseInt(tokenAmountObject.amount),
      tokenAmountObject.token.decimals
    );
    return {
      token: parseToken(tokenAmountObject.token),
      amount: scaledAmount,
    };
  } catch (e: any) {
    console.error('Unable to parse valid token amount', e);
    return {
      amount: 0,
      token: {
        name: '',
        address: '',
        token_id: '0',
        decimals: '0',
        standard: '',
      },
    };
  }
};
export const getTokensMetadata = async () => {
  const storage = await getTokenManagerStorage();
  const validTokens = storage['valid_tokens'];
  const names = validTokens.keys;
  return Promise.all(
    names.map(async token => {
      const t = await getTokenFromBigmap(validTokens.values, token);
      const icon = await fetch(
        `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/tokens?contract=${t.value.address}`
      )
        .then(t => t.json())
        .then(([t]) =>
          t?.metadata?.thumbnailUri
            ? `https://ipfs.io/ipfs/${t.metadata.thumbnailUri.split('//')[1]}`
            : undefined
        );

      return {
        name: t.value.name,
        address: t.value.address,
        icon,
      };
    })
  );
};


export const getTokensFromStorage = async () => {
  const storage = await getTokenManagerStorage();
  const validTokens = storage['valid_tokens'];
  const names = validTokens.keys;
  return Promise.all(
    names.map(async token => {
      const t = await getTokenFromBigmap(validTokens.values, token);

      return {
        name: t.value.name,
        address: t.value.address,
        decimals: t.value.decimals,
        standard: t.value.standard,
        tokenId: t.value.token_id,
      };
    })
  );
};

export const getSwapsFromStorage = async () => {
  const storage = await getTokenManagerStorage();
  const validSwaps = storage['valid_swaps'];
  const names = validSwaps.keys;
  return Promise.all(
    names.map(async swap => {
      const t = await getSwapFromBigmap(validSwaps.values, swap);

      const swp = {
        from: t.value.swap.from,
        to: t.value.swap.to,
      };

      return {
        swap: swp,
        oracle_address: t.value.oracle_address,
        oracle_asset_name: t.value.oracle_asset_name,
        oracle_precision: t.value.oracle_precision,
        is_disabled_for_deposits: t.value.is_disabled_for_deposits,
      };
    })
  );
}
