import { Dispatch, SetStateAction } from 'react';

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

export enum ToleranceType {
  MINUS = 0,
  EXACT = 1,
  PLUS = 2,
}

type Token = {
  name: string;
  address: string;
  decimal: number;
};

export type ExchangeProps = {
  baseToken: Token;
  quoteToken: Token;
  inversion: boolean;
  setInversion: Dispatch<SetStateAction<boolean>>;
};

export type BatcherInfoProps = {
  baseToken: Token;
  quoteToken: Token;
  inversion: boolean;
};

export type BatcherActionProps = {
  setContent: Dispatch<SetStateAction<ContentType>>;
};
