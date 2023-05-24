import { Option, None } from "prelude-ts";
export type liquidity_type = "jit" | "alwayson";

export type token_pair = {
  name: string;
  side: string;
  buy_limit_per_batch: number;
  buy_tolerance: string;
  sell_limit_per_batch: number;
  sell_tolerance: string;
};

export type liquidity_settings = {
  batcher_address: string;
  tezos_node_uri: string;
  tzkt_uri_api: string;
  token_pairs: Map<string, token_pair>;
};

export type token = {
  token_id: number;
  name: string;
  address: string;
  decimals: number;
  standard: string;
};

export type token_amount = {
  token: token;
  amount: number;
};

export type swap = {
  from: token_amount;
  to: token;
};

export type contract_details = {
  user_address: string;
  address: string;
  valid_tokens: Map<string, token>;
};

export type batch_provision = {
  batch_number: number;
  buy_side_provision: number;
  sell_side_provision: number;
};

export type order = {
  side: number;
  tolerance: number;
  swap: swap;
};
