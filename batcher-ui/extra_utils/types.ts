import { Dispatch, SetStateAction } from 'react';
import { TezosToolkit, WalletContract, MichelsonMap } from '@taquito/taquito';
import { StringNullableChain } from 'lodash';

export enum NetworkType {
  MAINNET = 'mainnet',
  GHOSTNET = 'ghostnet',
  MONDAYNET = 'mondaynet',
  DAILYNET = 'dailynet',
  DELPHINET = 'delphinet',
  EDONET = 'edonet',
  FLORENCENET = 'florencenet',
  GRANADANET = 'granadanet',
  HANGZHOUNET = 'hangzhounet',
  ITHACANET = 'ithacanet',
  JAKARTANET = 'jakartanet',
  KATHMANDUNET = 'kathmandunet',
  CUSTOM = 'custom',
}

export enum ContentType {
  SWAP = 'swap',
  ORDER_BOOK = 'order_book',
  REDEEM_HOLDING = 'redeem_holding',
  ABOUT = 'about',
  VOLUME = 'volume',
}

export enum selected_price {
  worse = 0,
  exact,
  better,
}

export class token {
  token_id!: number;
  name!: string;
  address: string | undefined;
  decimals!: number;
  standard!: string;
}

export class token_balance {
  token!: token;
  balance!: number;
}

export class token_amount {
  token!: token;
  amount!: number;
}

export class swap {
  from!: token_amount;
  to!: token;
}

export class float_t {
  pow!: number;
  val!: number;
}

export class exchange_rate {
  swap!: swap;
  rate!: float_t;
  when!: string;
}

export interface Side {
  bUY?: BUy;
  sELL?: SEll;
}

export interface BUy {}
export interface SEll {}

export interface Tolerance {
  eXACT?: EXact;
  mINUS?: MInus;
  pLUS?: PLus;
}

export interface EXact {}
export interface MInus {}
export interface PLus {}

export enum PriceType {
  WORSE = 0,
  EXACT = 1,
  BETTER = 2,
}

export enum SideType {
  BUY = 0,
  SELL = 1,
}

export class swap_order {
  trader!: string;
  swap!: swap;
  created_at!: string;
  side!: Side;
  tolerance!: Tolerance;
}

export class order_book {
  bids!: Array<any>;
  asks!: Array<any>;
}

export class token_holding {
  holder!: string;
  token_amount!: token_amount;
}

export class batch_status {
  open!: string;
}

export class batch {
  status!: batch_status;
  treasury!: MichelsonMap<string, Map<string, token_holding>>;
  orderbook!: order_book;
  pair!: [token, token];
}

export class batch_set {
  current!: batch;
  previous!: Array<batch>;
}
export class ContractStorage {
  valid_tokens!: Array<token>;
  valid_swaps!: Map<string, swap>;
  rates_current!: MichelsonMap<string, exchange_rate>;
  batches!: batch_set;
}

export class AddressData {
  address!: string;
}

export class TokenMetaData {
  name!: string;
  symbol!: string;
  decimals!: string;
}

export class TokenData {
  id!: number;
  contract!: AddressData;
  tokenId!: string;
  standard!: string;
  totalSupply!: string;
  metadata!: TokenMetaData;
}

export class ApiTokenBalanceData {
  id!: number;
  account!: AddressData;
  token!: TokenData;
  balance!: string;
  transfersCount!: number;
  firstLevel!: number;
  firstTime!: string;
  lastLevel!: number;
  lastTime!: string;
}

export type OrderBookProps = {
  orderBook: order_book;
  buyToken: token;
  sellToken: token;
};

export type ExchangeProps = {
  userAddress: string | undefined;
  buyBalance: number;
  sellBalance: number;
  inversion: boolean;
  fee_in_mutez: number;
  buyToken: token;
  sellToken: token;
  showDrawer(): void;
  updateAll: boolean;
  setUpdateAll: (_: boolean) => void;
  status: string;
  toggleInversion(): void;
};

export type BatcherInfoProps = {
  userAddress: string | undefined;
  tokenPair: string;
  buyBalance: number;
  sellBalance: number;
  buyTokenName: string;
  sellTokenName: string;
  inversion: boolean;
  rate: number;
  status: string;
  openTime: string | null;
  updateAll: boolean;
  setUpdateAll: Dispatch<SetStateAction<boolean>>;
  batchNumber: number;
};

export type BatcherActionProps = {
  content: ContentType;
  setContent: Dispatch<SetStateAction<ContentType>>;
};
export class aggregate_orders {
  buyside!: number;
  sellside!: number;
}
export class list_of_orders {
  ordertype!: string;
  price!: string;
  value!: number;
}

export enum BatcherStatus {
  NONE = 'none',
  OPEN = 'open',
  CLOSED = 'closed',
  CLEARED = 'cleared',
}

export type BatcherStepperProps = {
  status: string;
};

export type HoldingsProps = {
  userAddress: string | undefined;
  contractAddress: string;
  openHoldings: Map<string, number>;
  clearedHoldings: Map<string, number>;
  setOpenHoldings: Dispatch<SetStateAction<Map<string, number>>>;
  setClearedHoldings: Dispatch<SetStateAction<Map<string, number>>>;
  updateAll: boolean;
  setUpdateAll: Dispatch<SetStateAction<boolean>>;
  hasClearedHoldings: boolean;
};

export type Volumes = {
  buy_minus_volume: string;
  buy_exact_volume: string;
  buy_plus_volume: string;
  sell_minus_volume: string;
  sell_exact_volume: string;
  sell_plus_volume: string;
};

export type VolumeProps = {
  volumes: Volumes;
};

export const BUY = 'bUY';
export const SELL = 'sELL';
export const CLEARED = 'cleared';

export const MINUS = 'mINUS';
export const EXACT = 'eXACT';
export const PLUS = 'pLUS';

export type tokens = {
  buy_token_name: string;
  sell_token_name: string;
};
