#import "@ligo/math-lib/rational/rational.mligo" "Rational"

(* Side of an order, either BUY side or SELL side  *)
type side =
  Buy
  | Sell

(* Tolerance of the order against the oracle price  *)
type tolerance =
  Plus | Exact | Minus


type mint_burn_request = { 
   name: string;
   amount: nat;
}

type token = [@layout:comb] {
  token_id: nat;
  name : string;
  address : address option;
  decimals : nat;
  standard : string option;
}

(* A token value ascribes an amount to token metadata *)
type token_amount = [@layout:comb] {
  token : token;
  amount : nat;
}

type token_amount_map = (string, token_amount) map

type token_holding_map = (address, token_amount_map) map


(* A token amount 'held' by a specific address *)
type token_holding = [@layout:comb] {
  holder: address;
  token_amount : token_amount;
  redeemed: bool;
}

type swap =  [@layout:comb] {
 from : token_amount;
 to : token;
}

type swap_reduced = [@layout:comb] {
  from: string;
  to: string;
}

(* A valid swap is a swap pair that has a source of pricing from an oracle.  *)
type valid_swap_reduced = [@layout:comb] {
  swap: swap_reduced;
  oracle_address: address;
  oracle_asset_name: string;
  oracle_precision: nat;
  is_disabled_for_deposits: bool;
}
(* A valid swap is a swap pair that has a source of pricing from an oracle.  *)
type valid_swap = [@layout:comb] {
  swap: swap;
  oracle_address: address;
  oracle_asset_name: string;
  oracle_precision: nat;
  is_disabled_for_deposits: bool;
}


type exchange_rate_full = [@layout:comb] {
  swap : swap;
  rate: Rational.t;
  when : timestamp;
}

type exchange_rate = [@layout:comb] {
  swap : swap_reduced;
  rate: Rational.t;
  when : timestamp;
}

type swap_order =  [@layout:comb] {
  order_number: nat;
  batch_number: nat;
  trader : address;
  swap  : swap;
  side : side;
  tolerance : tolerance;
  redeemed:bool;
}

type external_swap_order = [@layout:comb] {
  swap  : swap;
  created_at : timestamp;
  side : nat;
  tolerance : nat;
}

type batch_status  =
  NOT_OPEN | OPEN | CLOSED | FINALIZED

type total_cleared_volumes = [@layout:comb] {
  buy_side_total_cleared_volume: nat;
  buy_side_volume_subject_to_clearing: nat;
  sell_side_total_cleared_volume: nat;
  sell_side_volume_subject_to_clearing: nat;

}

type clearing_volumes = [@layout:comb] {
  minus: nat;
  exact: nat;
  plus: nat;
}

type clearing =  [@layout:comb] {
  clearing_volumes : clearing_volumes;
  clearing_tolerance : tolerance;
  total_cleared_volumes: total_cleared_volumes;
  clearing_rate: exchange_rate;
}

(* These types are used in math module *)
type buy_minus_token = int
type buy_exact_token = int
type buy_plus_token = int
type buy_side = buy_minus_token * buy_exact_token * buy_plus_token

type sell_minus_token = int
type sell_exact_token = int
type sell_plus_token = int
type sell_side = sell_minus_token * sell_exact_token * sell_plus_token

type batch_status =
  | Open of { start_time : timestamp }
  | Closed of { start_time : timestamp ; closing_time : timestamp }
  | Cleared of { at : timestamp; clearing : clearing; rate : exchange_rate }

type volumes = [@layout:comb] {
  buy_minus_volume : nat;
  buy_exact_volume : nat;
  buy_plus_volume : nat;
  buy_total_volume : nat;
  sell_minus_volume : nat;
  sell_exact_volume : nat;
  sell_plus_volume : nat;
  sell_total_volume : nat;
}

type pair = string * string

(* This represents the type of order.  I.e. buy/sell and which level*)
type ordertype = [@layout:comb] {
   side: side;
   tolerance: tolerance;
}

(* Mapping order type to total amount of placed orders  *)
type ordertypes = (ordertype, nat) map

(* pairing of batch_id and ordertypes. *)
type batch_ordertypes = (nat,  ordertypes) map

(* Associated user address to a given set of batches and ordertypes  *)
type user_batch_ordertypes = (address, batch_ordertypes) big_map

(* Batch of orders for the same pair of tokens *)
type batch = [@layout:comb] {
  batch_number: nat;
  status : batch_status;
  volumes : volumes;
  pair : pair;
  holdings : nat;
  market_vault_used : side option;
}

type reduced_batch = [@layout:comb] {
  status: batch_status;
  volumes: volumes;
}

type batch_indices = (string,  nat) map

type batches = (nat, batch) big_map

type batch_set = [@layout:comb] {
  current_batch_indices: batch_indices;
  batches: batches;
}

(* Type for contract metadata *)
type metadata = (string, bytes) big_map

type metadata_update = {
  key: string;
  value: bytes;
}

type oracle_price_update = timestamp * nat

type oracle_source_change = [@layout:comb] {
  pair_name: string;
  oracle_address: address;
  oracle_asset_name: string;
  oracle_precision: nat;
}

(* The tokens that are valid within the contract  *)
type valid_tokens = (string, token) map

(* The swaps of valid tokens that are accepted by the contract  *)
type valid_swaps =  (string, valid_swap_reduced) map

(* The current, most up to date exchange rates between tokens  *)
type rates_current = (string, exchange_rate) big_map

type fees = {
   to_send: tez;
   to_refund: tez;
   payer: address;
   recipient: address;
}

type market_maker_vault = {
  total_shares: nat;
  holdings: nat set;
  native_token: token_amount;
  foreign_tokens: token_amount_map;
}

type market_vaults = (string, market_maker_vault) big_map

type market_vault_holding = {   
   id: nat;
   token: string;
   holder: address;
   shares: nat;
   unclaimed: tez;
}

type user_holding_key = address * string

type user_holdings =  (user_holding_key, nat) big_map

type vault_holdings = (nat, market_vault_holding) big_map

