import {
  BatchBigmap,
  OrderBookBigmap,
  RatesCurrentBigmap,
} from '@/types/contracts/batcher';

export type BigMapEvent = {
  data: Array<BigMapEventData>;
  state: number;
  type: number;
};

type BigMapEventData = {
  action: 'update_key' | 'add_key' | 'remove_key' | 'remove';
  bigmap: number; // bigmapId
  content: BigMapEventDataContent;
  contract: { address: string };
  id: number;
  level: number;
  path: 'batch_set.batches' | 'rates_current' | 'user_batch_ordertypes'; // path in bigmap
  timestamp: string;
};

type BigMapEventDataContent = {
  hash: string;
  key: string;
  value: RatesCurrentBigmap | BatchBigmap | OrderBookBigmap;
};
