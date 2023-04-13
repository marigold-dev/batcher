import { StringIterator } from 'lodash';
import * as types from './types';
import { Dispatch, SetStateAction } from 'react';

export const setTokenAmount = (balances: any[], standardBalance: number, tokenAddress: string, tokenDecimals: number, setBalance: Dispatch<SetStateAction<number>>) => {
  const item = balances.find(
    // eslint-disable-next-line @typescript-eslint/no-shadow
    (item) => item.token.contract.address === tokenAddress,
  );
  const tokAmount = item ? parseInt(item.balance) / 10 ** tokenDecimals : 0;
  setBalance(tokAmount);
};

export const scaleAmountDown = (amount: number, decimals: number) => {
  const scale = 10 ** -decimals;
  return amount * scale;
};
export const scaleAmountUp = (amount: number, decimals: number) => {
  const scale = 10 ** decimals;
  return amount * scale;
};

export const setSocketTokenAmount = (
  balances: any[],
  userAddress: string,
  token: types.token,
  setBalance: Dispatch<SetStateAction<number>>,
) => {
  const item = balances.find(
    // eslint-disable-next-line @typescript-eslint/no-shadow
    (item) => item.account.address === userAddress && item.token.contract.address === token.address,
  );
  const tokAmount = item ? parseInt(item.balance) / 10 ** token.decimals : 0;
  setBalance(tokAmount);
};

// Contract error codes
var error_codes = new Map([
  [ 100, "no_rate_available_for_swap " ],
  [ 101, "invalid token address " ],
  [ 102, "invalid_tezos_address" ],
  [ 103, "no_open_batch_for_deposits" ],
  [ 104, "batch_should_be_cleared" ],
  [ 105, "trying_to_close_batch_which_is_not_open" ],
  [ 106, "unable_to_parse_side_from_external_order" ],
  [ 107, "unable_to_parse_tolerance_from_external_order" ],
  [ 108, "token_standard_not_found" ],
  [ 109, "xtz_not_currently_supported" ],
  [ 110, "unsupported_swap_type" ],
  [ 111, "unable_to_reduce_token_amount_to_less_than_zero" ],
  [ 112, "too_many_unredeemed_orders" ],
  [ 113, "insufficient_swap_fee" ],
  [ 114, "sender_not_administrator" ],
  [ 115, "token_already_exists_but_details_are_different" ],
  [ 116, "swap_already_exists" ],
  [ 117, "swap_does_not_exist" ],
  [ 118, "endpoint_does_not_accept_tez" ],
  [ 119, "number_is_not_a_nat" ],
  [ 120, "oracle_price_is_stale" ],
  [ 121, "oracle_price_is_not_timely" ],
  [ 122, "unable_to_get_price_from_oracle" ],
  [ 123, "unable_to_get_price_from_new_oracle_source" ],
  [ 124, "oracle_price_should_be_available_before_deposit" ],
  [ 125, "swap_is_disabled_for_deposits" ],
  [ 126, "upper_limit_on_tokens_has_been_reached" ],
  [ 127, "upper_limit_on_swap_pairs_has_been_reached" ],
  [ 128, "cannot_reduce_limit_on_tokens_to_less_than_already_exists" ],
  [ 129, "cannot_reduce_limit_on_swap_pairs_to_less_than_already_exists" ],
  [ 130, "more_tez_sent_than_fee_cost" ],
  [ 131, "cannot_update_deposit_window_to_less_than_the_minimum" ],
  [ 132, "cannot_update_deposit_window_to_more_than_the_maximum" ],
  [ 133, "oracle_must_be_equal_to_minimum_precision" ],
  [ 134, "swap_precision_is_less_than_minimum" ],
  [ 135, "cannot_update_scale_factor_to_less_than_the_minimum" ],
  [ 136, "cannot_update_scale_factor_to_more_than_the_maximum" ],
  [ 137, "cannot_remove_swap_pair_that_is_not_disabled" ]
]);
export const getErrorMess = (error: any) => {
   try{

    const error_data_size = error.data.length;
    const error_code = error.data[error_data_size].with;
    const error_message  =  error_codes.get(error_code);
    return error_message;
   

   } catch {
  return error instanceof Error ? error.message : 'Unknown error';
   }
   

};

export const orders_exist_in_order_book = (ob: types.order_book) => {
  try {
    return ob.bids.length > 0 || ob.asks.length > 0;
  } catch {
    return false;
  }
};

export const getEmptyOrderBook = () => {
  return {
    bids: [],
    asks: [],
  };
};

export const getNetworkType = () => {
  const network = REACT_APP_NETWORK_TARGET;
  if (network?.includes('GHOSTNET')) {
    return types.NetworkType.GHOSTNET;
  } else {
    return types.NetworkType.KATHMANDUNET;
  }
};

export const getEmptyVolumes = () => {
  return {
    buy_minus_volume: '0',
    buy_exact_volume: '0',
    buy_plus_volume: '0',
    sell_minus_volume: '0',
    sell_exact_volume: '0',
    sell_plus_volume: '0',
  };
};

export const scaleStringAmountDown = (amount: string, decimals: number) => {
  if(!amount){
    console.error("scaleStringAmountDown - amount is undefined", amount)
    return '0';
  } else {
    const scale = 10 ** -decimals;
    return (Number.parseInt(amount) * scale).toString();
  }
};

