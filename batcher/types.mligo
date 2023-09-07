




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






type market_token = {
   circulation: nat;
   token: token;

}

(* Type for contract metadata *)
type metadata = (string, bytes) big_map

type metadata_update = {
  key: string;
  value: bytes;
}

let assert_some_or_fail_with
    (type a)
    (an_opt: a option)
    (error: nat) = 
    match an_opt with
    | None -> failwith error
    | Some _ -> ()

let assert_or_fail_with
    (predicate: bool)
    (error: nat) = 
    if not predicate then failwith error else ()

let find_or_fail_with
     (type a b)
     (key: a)
     (error: nat)
     (bmap:  (a,b) big_map) : b =
     match Big_map.find_opt key bmap with
     | None -> failwith error
     | Some v -> v

let bi_map_opt_sn
    (type a b)
    (f_some: a -> b)
    (f_none: unit -> b)
    (boxed: a option): b = 
    match boxed with
    | Some v -> f_some v
    | None -> f_none ()

let map_opt
   (type a b)
   (f: a -> b)
   (boxed: a option): b option = 
   match boxed with
   | None -> None
   | Some v -> Some (f v)

let bind_opt
  (type a b)
  (f: a -> b option)
  (boxed: a option): b option = 
  match boxed with
  | None -> None
  | Some v -> f v

