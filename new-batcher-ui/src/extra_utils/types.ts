import { Dispatch, SetStateAction } from 'react';
import { TezosToolkit, WalletContract, MichelsonMap } from '@taquito/taquito';

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
}

 export enum selected_tolerance{
    minus=0,
    exact,
    plus
  }

 export class token {
   name!: string;
   address!: string;
   decimals!:number;
  }

export class token_balance {
  token!: token;
  balance!:number;
}

export  class token_amount {
    token!: token;
    amount!: number;
  }

export  class swap {
     from!: token_amount;
     to!: token;
  }

export  class float_t {
    pow!: number;
    val!: number;
  }


export  class exchange_rate {
     swap!: swap;
     rate!: float_t;
     when!: string;
  }

export interface Tolerance {
  eXACT?: EXact
  mINUS?: MInus
  pLUS?: PLus
}

export interface EXact {}
export interface MInus {}
export interface PLus {}


export  class swap_order {
    trader!: string;
    swap!: swap;
    created_at!: string;
    side!: string;
    tolerance!: Tolerance;
  }

export  class order_book {
    bids!: Array<swap_order>;
    asks!: Array<swap_order>;
  }

export  class token_holding {
    holder!:string;
    token_amount!: token_amount;
}

export  class batch_status {
     open!: string;
  }

export  class batch {
      status!: batch_status;
      treasury!: MichelsonMap<string, Map<string, token_holding>>;
      orderbook!: order_book;
      pair!: [token, token];
  }

export  class batch_set {
     current!: batch;
     previous!: Array<batch>

  }
export  class ContractStorage {
    valid_tokens!: Array<token>;
    valid_swaps!: Map<string,swap>;
    rates_current!: MichelsonMap<string,exchange_rate>;
    batches!: batch_set;
  }



export  class AddressData {
     address!: string;
  }

export  class TokenMetaData {
    name!: string;
    symbol!: string;
    decimals!: string;
  }

export  class TokenData {
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
export type HoldingsProps = {
  tezos: TezosToolkit;
  bigMapsByIdUri: string;
  contractAddress: string;
  previousBatches: Array<batch>;
  buyToken: token;
  sellToken: token;
};


export type ExchangeProps = {
  buyToken: token;
  sellToken: token;
};

export type OrderBookProps = {
  orderBookExists: boolean;
  orderBook: order_book;
  buyToken: token;
  sellToken: token;
};

export type BatcherActionProps = {
  setContent: Dispatch<SetStateAction<ContentType>>;
};
export class aggregate_orders {
    buyside!: number;
    sellside!: number;
 }
export class list_of_orders {
   ordertype!:string;
   price!: string;
   value!: number;
}
