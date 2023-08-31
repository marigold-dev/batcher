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
  path: 'batch_set.batches' | 'rates_current' | 'user_batch_ordertypes'; // path dans la bigmap
  timestamp: string;
};

type BigMapEventDataContent = {
  hash: string;
  key: string;
  value: unknown;
};

// type OperationEvent = {
//   data: Array<unknown>;
//   state: number;
//   type: number;
// };

// type OperationEventData = {
//   type: 'transaction';
//   diffs: Array<unknown>;
//   storage: unknown;
//   timestamp: string;
// };

// type OperationEventDataDiffs = {
//   bigmap: number;
//   path: 'batch_set.batches' | 'rates_current'; // path dans la bigmap
//   action: 'update_key' | 'add_key' | 'remove_key' | 'remove';
//   content: OperationEventDataContent;
// };

// type OperationEventDataContent = {
//   hash: string;
//   key: string;
//   value: unknown;
// };

// rates current update_key

export type UpdateRateEvent = {
  swap: { from: string; to: string };
  rate: { p: number; q: number }; // float (Rational.t)
  when: number; // timestamp
};

export type BatchStatusOpen = { open: string };
export type BatchStatusClosed = {
  closed: { closing_time: string; start_time: string };
};
export type BatchStatusCleared = {
  cleared: {
    at: string;
    clearing: {
      clearing_rate: UpdateRateEvent;
      clearing_tolerance: {};
      clearing_volumes: { exact: string; minus: string; plus: string };
      total_cleared_volumes: {
        buy_side_total_cleared_volume: string;
        buy_side_volume_subject_to_clearing: string;
        sell_side_total_cleared_volume: string;
        sell_side_volume_subject_to_clearing: string;
      };
    };
    rate: UpdateRateEvent;
  };
};

export type BatcherStatusStorage =
  | BatchStatusOpen
  | BatchStatusClosed
  | BatchStatusCleared;

// Batch_set.batches add_key
export type Batch = {
  batch_number: number;
  pair: {
    address_0: string;
    address_1: string;
    decimals_0: string;
    decimals_1: string;
    name_0: string;
    name_1: string;
    standard_0: string;
    standard_1: string;
    token_id_0: string;
    token_id_1: string;
  };
  status: BatcherStatusStorage;
  volumes: {
    buy_minus_volume: string;
    buy_exact_volume: string;
    buy_plus_volume: string;
    sell_minus_volume: string;
    sell_exact_volume: string;
    sell_plus_volume: string;
  };
};
