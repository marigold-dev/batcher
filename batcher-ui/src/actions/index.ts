import { WalletActions } from './wallet';
import { ExchangeActions } from './exchange';

export * from './wallet';
export * from './exchange';

export type Actions = WalletActions | ExchangeActions;
