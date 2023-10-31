import { TokenManagerStorage, ValidTokensBigmapItem } from '@/types';
import { checkStatus } from '@/utils/utils';

const getTokenManagerStorage = (): Promise<TokenManagerStorage> =>
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
