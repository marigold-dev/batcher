#import "@ligo/math-lib/rational/rational.mligo" "Rational"

(* Errors  *)
[@inline] let no_rate_available_for_swap : nat                                   = 100n
[@inline] let invalid_token_address : nat                                        = 101n
[@inline] let invalid_tezos_address : nat                                        = 102n
[@inline] let no_open_batch : nat                                                = 103n
[@inline] let batch_should_be_cleared : nat                                      = 104n
[@inline] let trying_to_close_batch_which_is_not_open : nat                      = 105n
[@inline] let unable_to_parse_side_from_external_order : nat                     = 106n
[@inline] let unable_to_parse_tolerance_from_external_order : nat                = 107n
[@inline] let token_standard_not_found : nat                                     = 108n
[@inline] let xtz_not_currently_supported : nat                                  = 109n
[@inline] let unsupported_swap_type : nat                                        = 110n
[@inline] let unable_to_reduce_token_amount_to_less_than_zero : nat              = 111n
[@inline] let too_many_unredeemed_orders : nat                                   = 112n
[@inline] let insufficient_swap_fee : nat                                        = 113n
[@inline] let sender_not_administrator : nat                                     = 114n
[@inline] let token_already_exists_but_details_are_different: nat                = 115n
[@inline] let swap_already_exists: nat                                           = 116n
[@inline] let swap_does_not_exist: nat                                           = 117n
[@inline] let endpoint_does_not_accept_tez: nat                                  = 118n
[@inline] let number_is_not_a_nat: nat                                           = 119n
[@inline] let oracle_price_is_stale: nat                                         = 120n
[@inline] let oracle_price_is_not_timely: nat                                    = 121n
[@inline] let unable_to_get_price_from_oracle: nat                               = 122n
[@inline] let unable_to_get_price_from_new_oracle_source: nat                    = 123n
[@inline] let oracle_price_should_be_available_before_deposit: nat               = 124n
[@inline] let swap_is_disabled_for_deposits: nat                                 = 125n
[@inline] let upper_limit_on_tokens_has_been_reached: nat                        = 126n
[@inline] let upper_limit_on_swap_pairs_has_been_reached: nat                    = 127n
[@inline] let cannot_reduce_limit_on_tokens_to_less_than_already_exists: nat     = 128n
[@inline] let cannot_reduce_limit_on_swap_pairs_to_less_than_already_exists: nat = 129n
[@inline] let more_tez_sent_than_fee_cost : nat                                  = 130n
[@inline] let cannot_update_deposit_window_to_less_than_the_minimum : nat        = 131n
[@inline] let cannot_update_deposit_window_to_more_than_the_maximum : nat        = 132n
[@inline] let oracle_must_be_equal_to_minimum_precision : nat                    = 133n
[@inline] let swap_precision_is_less_than_minimum : nat                          = 134n
[@inline] let cannot_update_scale_factor_to_less_than_the_minimum : nat          = 135n
[@inline] let cannot_update_scale_factor_to_more_than_the_maximum : nat          = 136n
[@inline] let cannot_remove_swap_pair_that_is_not_disabled : nat                 = 137n
[@inline] let token_name_not_in_list_of_valid_tokens : nat                       = 138n
[@inline] let no_orders_for_user_address : nat                                   = 139n
[@inline] let cannot_cancel_orders_for_a_batch_that_is_not_open : nat            = 140n
[@inline] let cannot_decrease_holdings_of_removed_batch : nat                    = 141n
[@inline] let cannot_increase_holdings_of_batch_that_does_not_exist : nat        = 142n
[@inline] let batch_already_removed : nat                                        = 143n
[@inline] let admin_and_fee_recipient_address_cannot_be_the_same                 = 144n

(* Constants *)

(* The constant which represents a 10 basis point difference *)
[@inline] let ten_bips_constant = Rational.div (Rational.new 10001) (Rational.new 10000)

(* The constant which represents they4j period during which a closed batch will wait before looking for a price, in seconds. *)
[@inline] let price_wait_window_in_seconds : int = 120

(* The minimum length of a the scale factor for oracle staleness *)
(* Oracle prices would be considered stale if they are older than scale_factor_for_oracle_staleness * deposit_time_window *)
[@inline] let minimum_scale_factor_for_oracle_staleness : nat = 1n

(* The maximum length of a the scale factor for oracle staleness *)
(* Oracle prices would be considered stale if they are older than scale_factor_for_oracle_staleness * deposit_time_window *)
[@inline] let maximum_scale_factor_for_oracle_staleness : nat = 10n

(* The minimum length of a deposit price window *)
[@inline] let minimum_deposit_time_in_seconds : nat = 600n

(* The maximum length of a deposit price window *)
[@inline] let maximum_deposit_time_in_seconds : nat = 3600n

[@inline] let fa12_token : string = "FA1.2 token"

[@inline] let fa2_token : string = "FA2 token"

[@inline] let limit_of_redeemable_items : nat = 10n

(* The contract assumes that the minimum precision is six and that the oracle precision must EXACTLY be 6 *)
[@inline] let minimum_precision : nat = 6n



(* Associate alias to token address *)
type token = [@layout:comb] {
  token_id: nat;
  name : string;
  address : address option;
  decimals : nat;
  standard : string option;
}

(* Side of an order, either BUY side or SELL side  *)
type side =
  Buy
  | Sell

(* Tolerance of the order against the oracle price  *)
type tolerance =
  Plus | Exact | Minus

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
}

type batch_indices = (string,  nat) map

type batches = (nat, batch) big_map

(* Set of batches, containing the current batch and the previous (finalized) batches.
   The current batch can be open for deposits, closed for deposits (awaiting clearing) or
   finalized, as we wait for a new deposit to start a new batch *)
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


type orace_price_update = timestamp * nat

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


[@inline]
let get_token
  (token_name: string)
  (tokens: valid_tokens): token =
  let tok_opt = Map.find_opt token_name tokens in
  match tok_opt with
  | Some t -> t
  | None -> failwith unable_to_reduce_token_amount_to_less_than_zero

module TokenAmount = struct

  let recover
  (ot: ordertype)
  (amt: nat)
  (c: clearing)
  (tokens: valid_tokens): token_amount =
  let swap = c.clearing_rate.swap in
  let token = match ot.side with
             | Buy -> get_token swap.from tokens
             | Sell -> get_token swap.to tokens
  in
  {
    token = token;
    amount = amt;
  }
end

module TokenAmountMap = struct

  type op = Increase | Decrease

  let amend
  (ta: token_amount)
  (op: op)
  (tam : token_amount_map): token_amount_map =
  let token_name = ta.token.name in
  match Map.find_opt token_name tam with
  | None -> Map.add token_name ta tam
  | Some prev -> let new_amt: nat = match op with
                                    | Increase -> ta.amount + prev.amount
                                    | Decrease -> if ta.amount > prev.amount then
                                                    (failwith unable_to_reduce_token_amount_to_less_than_zero : nat)
                                                  else
                                                    abs (prev.amount - ta.amount)
                 in
                 let new_tamt = { ta with amount = new_amt } in
                 Map.update token_name (Some new_tamt) tam

  let increase
  (ta: token_amount)
  (tam : token_amount_map): token_amount_map =
  amend ta Increase tam

end

module BatchHoldings_Utils = struct


[@inline]
let increase_holding
  (batch_number: nat)
  (batches: batches): batches =
  match Big_map.find_opt batch_number batches with
  | None  -> failwith cannot_increase_holdings_of_batch_that_does_not_exist
  | Some b -> let bh = b.holdings + 1n in
              let b = { b with holdings = bh; } in
              Big_map.update batch_number (Some b) batches

[@inline]
let add_batch_holding
  (batch_number: nat)
  (address: address)
  (ubots: user_batch_ordertypes)
  (batches: batches): batches =
  match Big_map.find_opt address ubots with
  | Some bots -> (match Map.find_opt batch_number bots with
                  | Some _ -> batches
                  | None   -> increase_holding batch_number batches)
  | None -> increase_holding batch_number batches

[@inline]
let remove_batch_holding
  (batch_number: nat)
  (batches: batches): batches =
  match Big_map.find_opt batch_number batches with
  | None -> failwith cannot_decrease_holdings_of_removed_batch
  | Some b -> let nh = abs(b.holdings - 1n) in
              let b = { b with holdings = nh; } in
              Big_map.update batch_number (Some b) batches


[@inline]
let can_batch_be_removed
  (batch_number: nat)
  (batches: batches): bool =
  match Big_map.find_opt batch_number batches with
                | None -> failwith cannot_decrease_holdings_of_removed_batch
                | Some b -> b.holdings <= 0n

end


module Storage = struct

  type t = {
    metadata: metadata;
    valid_tokens : valid_tokens;
    valid_swaps : valid_swaps;
    rates_current : rates_current;
    batch_set : batch_set;
    last_order_number : nat;
    user_batch_ordertypes: user_batch_ordertypes;
    fee_in_mutez: tez;
    fee_recipient : address;
    administrator : address;
    limit_on_tokens_or_pairs : nat;
    deposit_time_window_in_seconds : nat;
  }

end

module Utils = struct


[@inline]
let swap_to_swap_reduced
  (swap: swap): swap_reduced =
  {
   from = swap.from.token.name;
   to = swap.to.name;
  }

[@inline]
let valid_swap_to_valid_swap_reduced
  (valid_swap: valid_swap) : valid_swap_reduced =
  let swap_reduced = swap_to_swap_reduced valid_swap.swap in
  {
   swap = swap_reduced;
   oracle_address = valid_swap.oracle_address;
   oracle_asset_name = valid_swap.oracle_asset_name;
   oracle_precision = valid_swap.oracle_precision;
   is_disabled_for_deposits = valid_swap.is_disabled_for_deposits;
  }

[@inline]
let swap_reduced_to_swap
  (swap_reduced: swap_reduced)
  (from_amount: nat)
  (tokens: valid_tokens) : swap =
  let from = get_token swap_reduced.from tokens in
  let to = get_token swap_reduced.to tokens in
  {
    from = {
        token = from;
        amount = from_amount;
      };
      to = to;
    }


[@inline]
let valid_swap_reduced_to_valid_swap
  (valid_swap_reduced: valid_swap_reduced)
  (from_amount: nat)
  (tokens: valid_tokens) : valid_swap =
  let swap = swap_reduced_to_swap valid_swap_reduced.swap from_amount tokens in
  {
   swap = swap;
   oracle_address = valid_swap_reduced.oracle_address;
   oracle_precision = valid_swap_reduced.oracle_precision;
   oracle_asset_name = valid_swap_reduced.oracle_asset_name;
   is_disabled_for_deposits = valid_swap_reduced.is_disabled_for_deposits;
  }


[@inline]
let empty_total_cleared_volumes : total_cleared_volumes = {
  buy_side_total_cleared_volume = 0n;
  buy_side_volume_subject_to_clearing = 0n;
  sell_side_total_cleared_volume = 0n;
  sell_side_volume_subject_to_clearing = 0n;
}

[@inline]
let to_nat (i:int): nat =
  match is_nat i with
  | Some n -> n
  | None -> failwith number_is_not_a_nat

[@inline]
let gt (a : Rational.t) (b : Rational.t) : bool = not (Rational.lte a b)

[@inline]
let gte (a : Rational.t) (b : Rational.t) : bool = not (Rational.lt a b)

let pow (base : int) (pow : int) : int =
  let rec iter (acc : int) (rem_pow : int) : int = if rem_pow = 0 then acc else iter (acc * base) (rem_pow - 1) in
  iter 1 pow

(* Get the number with 0 decimal accuracy *)
[@inline]
let get_rounded_number_lower_bound (number : Rational.t) : nat =
  let zero_decimal_number = Rational.resolve number 0n in
    to_nat zero_decimal_number

[@inline]
let get_min_number (a : Rational.t) (b : Rational.t) =
  if Rational.lte a b then a
  else b

[@inline]
let get_clearing_tolerance
  (cp_minus : Rational.t)
  (cp_exact : Rational.t)
  (cp_plus : Rational.t) : tolerance =
  if gte cp_minus cp_exact && gte cp_minus cp_plus then Minus
  else if gte cp_exact cp_minus && gte cp_exact cp_plus then Exact
  else Plus

[@inline]
let get_cp_minus
  (rate : Rational.t)
  (buy_side : buy_side)
  (sell_side : sell_side) : Rational.t =
  let buy_minus_token, _, _ = buy_side in
  let sell_minus_token, sell_exact_token, sell_plus_token = sell_side in
  let left_number = Rational.new (buy_minus_token)  in
  let right_number = Rational.div (Rational.mul (Rational.new (sell_minus_token + sell_exact_token + sell_plus_token)) ten_bips_constant) rate in
  let min_number = get_min_number left_number right_number in
  min_number

[@inline]
let get_cp_exact
  (rate : Rational.t)
  (buy_side : buy_side)
  (sell_side : sell_side) : Rational.t =
  let buy_minus_token, buy_exact_token, _ = buy_side in
  let _, sell_exact_token, sell_plus_token = sell_side in
  let left_number = Rational.new (buy_minus_token + buy_exact_token) in
  let right_number = Rational.div (Rational.new (sell_exact_token + sell_plus_token)) rate in
  let min_number = get_min_number left_number right_number in
  min_number

[@inline]
let get_cp_plus
  (rate : Rational.t)
  (buy_side : buy_side)
  (sell_side : sell_side) : Rational.t =
  let buy_minus_token, buy_exact_token, buy_plus_token = buy_side in
  let _, _, sell_plus_token = sell_side in
  let left_number = Rational.new (buy_minus_token + buy_exact_token + buy_plus_token) in
  let right_number = Rational.div (Rational.new (sell_plus_token)) (Rational.mul ten_bips_constant rate) in
  let min_number = get_min_number left_number right_number in
  min_number

[@inline]
let get_clearing_price (exchange_rate : exchange_rate) (buy_side : buy_side) (sell_side : sell_side) : clearing =
  let rate = exchange_rate.rate in
  let cp_minus = get_cp_minus rate buy_side sell_side in
  let cp_exact = get_cp_exact rate buy_side sell_side in
  let cp_plus = get_cp_plus rate buy_side sell_side in
  let rounded_cp_minus = get_rounded_number_lower_bound cp_minus in
  let rounded_cp_exact = get_rounded_number_lower_bound cp_exact in
  let rounded_cp_plus = get_rounded_number_lower_bound cp_plus in
  let clearing_volumes =
    {
      minus = rounded_cp_minus;
      exact = rounded_cp_exact;
      plus = rounded_cp_plus
    }
  in
  let clearing_tolerance = get_clearing_tolerance cp_minus cp_exact cp_plus in
  {
    clearing_volumes = clearing_volumes;
    clearing_tolerance = clearing_tolerance;
    total_cleared_volumes = empty_total_cleared_volumes;
    clearing_rate = exchange_rate
  }

[@inline]
let nat_to_side
(order_side : nat) : side =
  if order_side = 0n then Buy
  else
    if order_side = 1n then Sell
    else failwith unable_to_parse_side_from_external_order

[@inline]
let nat_to_tolerance (tolerance : nat) : tolerance =
  if tolerance = 0n then Minus
  else if tolerance = 1n then Exact
  else if tolerance = 2n then Plus
  else failwith unable_to_parse_tolerance_from_external_order

[@inline]
let find_lexicographical_pair_name
  (token_one_name: string)
  (token_two_name: string) : string =
  if token_one_name > token_two_name then
    token_one_name ^ "/" ^ token_two_name
  else
    token_two_name ^ "/" ^ token_one_name

[@inline]
let get_rate_name_from_swap (s : swap_reduced) : string =
  let base_name = s.from in
  let quote_name = s.to in
  find_lexicographical_pair_name quote_name base_name

[@inline]
let get_rate_name_from_pair (s : pair) : string =
  let base_name, quote_name = s in
  find_lexicographical_pair_name quote_name base_name

[@inline]
let get_inverse_rate_name_from_pair (s :  pair) : string =
  let base_name, quote_name = s in
  find_lexicographical_pair_name quote_name base_name

[@inline]
let get_rate_name
  (r : exchange_rate): string =
  let base_name = r.swap.from in
  let quote_name = r.swap.to in
  find_lexicographical_pair_name quote_name base_name


[@inline]
let pair_of_swap
  (side: side)
  (swap: swap_reduced): (pair) =
  match side with
  | Buy -> swap.from, swap.to
  | Sell -> swap.to, swap.from

[@inline]
let pair_of_rate
  (r : exchange_rate): pair = pair_of_swap Buy r.swap

[@inline]
let pair_of_external_swap
  (order : external_swap_order): pair =
  (* Note:  we assume left-handedness - i.e. direction is buy side*)
  let swap = order.swap in
  let side = nat_to_side order.side in
  let swap_reduced = swap_to_swap_reduced swap in
  pair_of_swap side swap_reduced

[@inline]
let get_current_batch_index
  (pair: pair)
  (batch_indices: batch_indices): nat =
  let rate_name = get_rate_name_from_pair pair in
  match Map.find_opt rate_name batch_indices with
  | Some cbi -> cbi
  | None -> 0n


[@inline]
let get_highest_batch_index
  (batch_indices: batch_indices) : nat =
  let return_highest (acc, (_s, i) :  nat * (string * nat)) : nat = if i > acc then
                                                                      i
                                                                    else
                                                                      acc
  in
  Map.fold return_highest batch_indices 0n

(** [concat a b] concat [a] and [b]. *)
let concat1 (type a) (left: a list) (right: a list) : a list =
  List.fold_right (fun (x, xs: a * a list) -> x :: xs) left right

(** [rev list] should return the same list reversed. *)
let rev1 (type a) (list: a list) : a list =
  List.fold_left (fun (xs, x : a list * a) -> x :: xs) ([] : a list) list

[@inline]
let update_if_more_recent
  (rate_name: string)
  (rate: exchange_rate)
  (rates_current: rates_current) : rates_current =
  match Big_map.find_opt rate_name rates_current with
  | None -> Big_map.add rate_name rate rates_current
  | Some lr -> if rate.when > lr.when then
                  Big_map.update rate_name (Some rate) rates_current
                else
                  rates_current

[@inline]
let update_current_rate (rate_name : string) (rate : exchange_rate) (storage : Storage.t) =
  let updated_rates = update_if_more_recent rate_name rate storage.rates_current in
  { storage with rates_current = updated_rates }

[@inline]
let get_rate_scaling_power_of_10
  (rate : exchange_rate)
  (tokens: valid_tokens): Rational.t =
  let swap = rate.swap in
  let from_token = get_token swap.from tokens in
  let to_token = get_token swap.to tokens in
  let from_decimals = from_token.decimals in
  let to_decimals = to_token.decimals in
  let diff = to_decimals - from_decimals in
  let abs_diff = int (abs diff) in
  let power10 = pow 10 abs_diff in
  if diff = 0 then
    Rational.new 1
  else
    if diff < 0 then
      Rational.div (Rational.new 1) (Rational.new power10)
    else
      (Rational.new power10)

[@inline]
let scale_on_receive_for_token_precision_difference
  (rate : exchange_rate)
  (tokens: valid_tokens): exchange_rate =
  let scaling_rate = get_rate_scaling_power_of_10 rate tokens in
  let adjusted_rate = Rational.mul rate.rate scaling_rate in
  { rate with rate = adjusted_rate }



end

module OrderType = struct

[@inline]
let make
    (order: swap_order) : ordertype =
    {
      tolerance = order.tolerance;
      side = order.side;
    }

end

module OrderTypes = struct

[@inline]
let make
    (order: swap_order) : ordertypes =
    let ot = OrderType.make order in
    let new_map = (Map.empty : ordertypes) in
    Map.add ot order.swap.from.amount new_map

[@inline]
let update
    (order: swap_order)
    (bot: ordertypes) : ordertypes =
    let ot: ordertype = OrderType.make order in
    match Map.find_opt ot bot with
    | None -> Map.add ot order.swap.from.amount bot
    | Some amt -> let new_amt = amt + order.swap.from.amount in
                  Map.update ot (Some new_amt) bot

[@inline]
let count
  (ots: ordertypes) : nat = Map.size ots

end

module Batch_OrderTypes = struct

[@inline]
let make
  (batch_id: nat)
  (order: swap_order): batch_ordertypes =
  let new_ot : ordertypes  = OrderTypes.make order in
  Map.literal [(batch_id, new_ot)]

[@inline]
let add_or_update
  (batch_id: nat)
  (order: swap_order)
  (bots: batch_ordertypes): batch_ordertypes =
  match Map.find_opt batch_id bots with
  | None -> let new_ot: ordertypes = OrderTypes.make order in
            Map.add batch_id new_ot bots
  | Some bot -> let updated_bot : ordertypes = OrderTypes.update order bot in
                Map.update batch_id (Some updated_bot) bots

[@inline]
let count
  (bots: batch_ordertypes) : nat =
  let count_aux
    (acc, (_batch_number, ots): nat * (nat * ordertypes)) : nat =
    let ots_count = OrderTypes.count ots in
    acc + ots_count
  in
  Map.fold count_aux bots 0n

end

module Redemption_Utils = struct

[@inline]
let was_in_clearing_for_buy
  (clearing_tolerance: tolerance)
  (order_tolerance: tolerance) : bool =
    match order_tolerance, clearing_tolerance with
    | Exact,Minus -> false
    | Plus,Minus -> false
    | Minus,Exact -> true
    | Plus,Exact -> false
    | Minus,Plus -> true
    | Exact,Plus -> true
    | _,_ -> true

[@inline]
let was_in_clearing_for_sell
  (clearing_tolerance: tolerance)
  (order_tolerance: tolerance) : bool =
    match order_tolerance, clearing_tolerance with
    | Exact,Minus -> true
    | Plus,Minus -> true
    | Minus,Exact -> false
    | Plus,Exact -> true
    | Minus,Plus -> false
    | Exact,Plus -> false
    | _,_ -> true

[@inline]
let was_in_clearing
  (volumes:volumes)
  (ot: ordertype)
  (clearing: clearing) : bool =
  if volumes.buy_total_volume = 0n then false else
  if volumes.sell_total_volume = 0n then false else
  let order_tolerance = ot.tolerance in
  let order_side = ot.side in
  let clearing_tolerance = clearing.clearing_tolerance in
  match order_side with
  | Buy -> was_in_clearing_for_buy clearing_tolerance order_tolerance
  | Sell -> was_in_clearing_for_sell clearing_tolerance order_tolerance


[@inline]
let get_clearing_volume
  (clearing:clearing) : nat =
  match clearing.clearing_tolerance with
  | Minus -> clearing.clearing_volumes.minus
  | Exact -> clearing.clearing_volumes.exact
  | Plus -> clearing.clearing_volumes.plus

(* Filter 0 amount transfers out *)
[@inline]
let add_payout_if_not_zero
  (payout: token_amount)
  (tam: token_amount_map) : token_amount_map =
  if payout.amount > 0n then
    TokenAmountMap.increase payout tam
  else
    tam

[@inline]
let get_cleared_sell_side_payout
  (from: token)
  (to: token)
  (amount: nat)
  (clearing: clearing)
  (tam: token_amount_map ): token_amount_map =
  let tc = clearing.total_cleared_volumes in
  (* Find the buy side volume in buy token units that was cleared.  This doesn't include all the volume that was subject to clearing, but just that which can be cleared on both sides of the trade  *)
  let f_buy_side_cleared_volume = Rational.new (int tc.buy_side_total_cleared_volume) in
  (* Find the sell side volume in sell token units that was included in the clearing.  This doesn't not include the volume of any orders that were outside the price *)
  (* This will be used to calculate the prorata allocation of the order amount against the volume that was included in clearing *)
  let f_sell_side_volume_subject_to_clearing = Rational.new (int tc.sell_side_volume_subject_to_clearing) in
  (* Represent the amount of user sell order as a rational *)
  let f_amount = Rational.new (int amount) in
  (* The pro rata allocation of the user's order amount in the context of the cleared volume.  This is represented as a percentage of the total volume that was subject to clearing *)
  let prorata_allocation = Rational.div f_amount f_sell_side_volume_subject_to_clearing in
  (* Given the buy side volume that is available to settle the order, calculate the payout in buy tokens for the prorata amount  *)
  let payout = Rational.mul prorata_allocation f_buy_side_cleared_volume in
  (* Given the buy side payout, calculate in sell side units so the remainder of a partial fill can be calculated *)
  let payout_equiv = Rational.mul payout clearing.clearing_rate.rate in
  (* Calculate the remaining amount on the sell side of a partial fill *)
  let remaining = Rational.sub f_amount payout_equiv in
  (* Build payout amount *)
  let fill_payout: token_amount = {
    token = to;
    amount = Utils.get_rounded_number_lower_bound payout;
  } in
  (* Add payout to transfers if not zero  *)
  let u_tam = add_payout_if_not_zero fill_payout tam in
  (* Check if there is a partial fill.  If so add partial fill payout plus remainder otherwise just add payout  *)
  if Utils.gt remaining (Rational.new 0) then
    let token_rem : token_amount = {
        token = from;
        amount = Utils.get_rounded_number_lower_bound remaining;
    } in
    TokenAmountMap.increase token_rem u_tam
  else
    u_tam

[@inline]
let get_cleared_buy_side_payout
  (from: token)
  (to: token)
  (amount: nat)
  (clearing:clearing)
  (tam: token_amount_map): token_amount_map =
  let tc = clearing.total_cleared_volumes in
  (* Find the sell side volume in sell token units that was cleared.  This doesn't include all the volume that was subject to clearing, but just that which can be cleared on both sides of the trade  *)
  let f_sell_side_cleared_volume = Rational.new (int tc.sell_side_total_cleared_volume) in
  (* Find the buy side volume that was included in the clearing.  This doesn't not include the volume of any orders that were outside the price *)
  let f_buy_side_actual_volume_subject_to_clearing = Rational.new (int tc.buy_side_volume_subject_to_clearing) in
  (* Represent the amount of user buy order as a rational *)
  let f_amount = Rational.new (int amount) in
  (* The pro rata allocation of the user's order amount in the context of the cleared volume.  This is represented as a percentage of the cleared total volume *)
  let prorata_allocation = Rational.div f_amount f_buy_side_actual_volume_subject_to_clearing in
  (* Given the sell side volume that is available to settle the order, calculate the payout in sell tokens for the prorata amount  *)
  let payout = Rational.mul prorata_allocation f_sell_side_cleared_volume in
  (* Given the sell side payout, calculate in buy side units so the remainder of a partial fill can be calculated *)
  let payout_equiv = Rational.div payout clearing.clearing_rate.rate in
  (* Calculate the remaining amount on the buy side of a partial fill *)
  let remaining = Rational.sub f_amount payout_equiv in
  (* Build payout amount *)
  let fill_payout = {
    token = to;
    amount = Utils.get_rounded_number_lower_bound payout;
  } in
  (* Add payout to transfers if not zero  *)
  let u_tam = add_payout_if_not_zero fill_payout tam in
  (* Check if there is a partial fill.  If so add partial fill payout plus remainder otherwise just add payout  *)
  if Utils.gt remaining (Rational.new 0) then
    let token_rem = {
        token = from;
        amount = Utils.get_rounded_number_lower_bound remaining;
    } in
    TokenAmountMap.increase token_rem u_tam
  else
    u_tam

[@inline]
let get_cleared_payout
  (ot: ordertype)
  (amt: nat)
  (clearing: clearing)
  (tam: token_amount_map)
  (tokens: valid_tokens): token_amount_map =
  let s = ot.side in
  let swap = clearing.clearing_rate.swap in
  let from_token = get_token swap.from tokens in
  let to_token = get_token swap.to tokens in
  match s with
  | Buy -> get_cleared_buy_side_payout from_token to_token amt clearing tam
  | Sell -> get_cleared_sell_side_payout to_token from_token amt clearing tam


[@inline]
let collect_order_payout_from_clearing
  ((c, tam, vols, tokens, fees, fee_in_mutez), (ot, amt): (clearing * token_amount_map * volumes * valid_tokens * fees * tez) * (ordertype * nat)) :  (clearing * token_amount_map * volumes * valid_tokens * fees * tez) =
  let (u_tam, u_fees) = if was_in_clearing vols ot c then
                          let tm = get_cleared_payout ot amt c tam tokens in
                          let f = fees.to_send + fee_in_mutez in
                          let uf = { fees with to_send = f; } in
                          (tm, uf)
                        else
                          let ta: token_amount = TokenAmount.recover ot amt c tokens in
                          let f = fees.to_refund + fee_in_mutez in
                          let uf = { fees with to_refund = f; } in
                          (TokenAmountMap.increase ta tam, uf)
  in
  (c, u_tam, vols, tokens, u_fees, fee_in_mutez)

end

module Ubots = struct

[@inline]
let add_order
    (holder: address)
    (batch_id: nat)
    (order : swap_order)
    (ubots: user_batch_ordertypes) : user_batch_ordertypes =
    match Big_map.find_opt holder ubots with
    | None -> let new_bots = Batch_OrderTypes.make batch_id order in
              Big_map.add holder new_bots ubots
    | Some bots -> let updated_bots = Batch_OrderTypes.add_or_update batch_id order bots in
                   Big_map.update holder (Some updated_bots) ubots

[@inline]
let get_clearing
   (batch: batch) : clearing option =
   match batch.status with
   | Cleared ci -> Some ci.clearing
   | _ -> None


[@inline]
let collect_redemptions
    ((bots, tam, bts, tokens, fees, fee_in_mutez),(batch_number,otps) : (batch_ordertypes * token_amount_map * batch_set * valid_tokens * fees * tez) * (nat * ordertypes)) : (batch_ordertypes * token_amount_map * batch_set * valid_tokens * fees * tez) =
    let batches = bts.batches in
    match Big_map.find_opt batch_number batches with
    | None -> bots, tam, bts, tokens, fees, fee_in_mutez
    | Some batch -> (match get_clearing batch with
                      | None -> bots, tam, bts, tokens, fees, fee_in_mutez
                      | Some c -> let _c, u_tam, _vols, _tokns, fs, _fim = Map.fold Redemption_Utils.collect_order_payout_from_clearing otps (c, tam, batch.volumes, tokens, fees, fee_in_mutez)  in
                                  let batches = BatchHoldings_Utils.remove_batch_holding batch.batch_number batches in
                                  let bts = if BatchHoldings_Utils.can_batch_be_removed batch.batch_number batches then
                                              let batches = Big_map.remove batch.batch_number bts.batches in
                                              { bts with batches = batches;  }
                                            else
                                              { bts with batches = batches;  }
                                  in
                                  let u_bots = Map.remove batch_number bots in
                                  u_bots,u_tam, bts, tokens, fs, fee_in_mutez)

[@inline]
let collect_redemption_payouts
    (holder: address)
    (fees: fees)
    (storage: Storage.t):  (fees * user_batch_ordertypes * batch_set * token_amount_map) =
    let fee_in_mutez = storage.fee_in_mutez in
    let batch_set = storage.batch_set in
    let ubots = storage.user_batch_ordertypes in
    let tokens = storage.valid_tokens in
    let empty_tam = (Map.empty : token_amount_map) in
    match Big_map.find_opt holder ubots with
    | None -> fees, ubots, batch_set, empty_tam
    | Some bots -> let u_bots, u_tam, bs, _tkns, u_fees, _fim = Map.fold collect_redemptions bots (bots, empty_tam, batch_set, tokens, fees, fee_in_mutez) in
                   let updated_ubots = Big_map.update holder (Some u_bots) ubots in
                   u_fees, updated_ubots,  bs, u_tam


[@inline]
let is_within_limit
  (holder: address)
  (ubots: user_batch_ordertypes) : bool =
  match Big_map.find_opt holder ubots with
  | None  -> true
  | Some bots -> let outstanding_token_items = Batch_OrderTypes.count bots in
                 outstanding_token_items <= limit_of_redeemable_items

end


module Treasury_Utils = struct

  type adjustment = INCREASE | DECREASE
  type order_list = swap_order list

 type atomic_trans =
    [@layout:comb] {
    to_  : address;
    token_id : nat;
    amount : nat;
  }

  type transfer_from = {
    from_ : address;
    tx : atomic_trans list
  }

  (* Transferred format for tokens in FA2 standard *)
  type fa2_transfer = transfer_from list

  (* Transferred format for tokens in FA12 standard *)
  type fa12_transfer =
    [@layout:comb] {
    [@annot:from] address_from : address;
    [@annot:to] address_to : address;
    value : nat
  }



[@inline]
let transfer_fa12_token
  (sender : address)
  (receiver : address)
  (token_address : address)
  (token_amount : nat) : operation =
    let transfer_entrypoint : fa12_transfer contract =
      match (Tezos.get_entrypoint_opt "%transfer" token_address : fa12_transfer contract option) with
      | None -> failwith invalid_token_address
      | Some transfer_entrypoint -> transfer_entrypoint
    in
    let transfer : fa12_transfer = {
      address_from = sender;
      address_to = receiver;
      value = token_amount
    } in
    Tezos.transaction transfer 0tez transfer_entrypoint

[@inline]
let transfer_fa2_token
  (sender : address)
  (receiver : address)
  (token_address : address)
  (token_id: nat)
  (token_amount : nat) : operation =
    let transfer_entrypoint : fa2_transfer contract =
      match (Tezos.get_entrypoint_opt "%transfer" token_address : fa2_transfer contract option) with
      | None -> failwith invalid_token_address
      | Some transfer_entrypoint -> transfer_entrypoint
    in
    let transfer : fa2_transfer = [
      {
        from_ = sender;
        tx = [
          {
            to_ = receiver;
            token_id = token_id;
            amount = token_amount
          }
        ]
      }
    ] in
    Tezos.transaction transfer 0tez transfer_entrypoint

(* Transfer the tokens to the appropriate address. This is based on the FA12 and FA2 token standard *)
[@inline]
let transfer_token
  (sender : address)
  (receiver : address)
  (token_address : address)
  (token_amount : token_amount) : operation =
  match token_amount.token.standard with
  | Some standard ->
    if standard = fa12_token then
      transfer_fa12_token sender receiver token_address token_amount.amount
    else if standard = fa2_token then
      transfer_fa2_token sender receiver token_address token_amount.token.token_id token_amount.amount
    else
      failwith token_standard_not_found
  | None ->
      failwith token_standard_not_found

[@inline]
let handle_transfer (sender : address) (receiver : address) (received_token : token_amount) : operation =
  match received_token.token.address with
  | None -> failwith xtz_not_currently_supported
  | Some token_address ->
      transfer_token sender receiver token_address received_token

[@inline]
let transfer_holdings (treasury_vault : address) (holder: address)  (holdings : token_amount_map) : operation list =
  let atomic_transfer (operations, (_token_name,ta) : operation list * ( string * token_amount)) : operation list =
    let op: operation = handle_transfer treasury_vault holder ta in
    op :: operations
  in
  let op_list = Map.fold atomic_transfer holdings ([] : operation list)
  in
  op_list

[@inline]
let transfer_fee (receiver : address) (amount : tez) : operation =
    match (Tezos.get_contract_opt receiver : unit contract option) with
    | None -> failwith invalid_tezos_address
    | Some rec_address -> Tezos.transaction () amount rec_address


end


module Treasury = struct

type storage = Storage.t

[@inline]
let get_treasury_vault () : address = Tezos.get_self_address ()

[@inline]
let resolve_fees
  (fees: fees)
  (token_ops: operation list): operation list =
  let token_ops =
    if fees.to_refund > 0mutez then
      Treasury_Utils.transfer_fee fees.payer fees.to_refund :: token_ops
    else
      token_ops
  in
  if fees.to_send > 0mutez then
    Treasury_Utils.transfer_fee fees.recipient fees.to_send :: token_ops
  else
    token_ops

[@inline]
let deposit
    (deposit_address : address)
    (deposited_token : token_amount) : operation list  =
      let treasury_vault = get_treasury_vault () in
      let deposit_op = Treasury_Utils.handle_transfer deposit_address treasury_vault deposited_token in
      [ deposit_op]


[@inline]
let redeem
    (redeem_address : address)
    (storage : storage) : operation list * storage =
      let treasury_vault = get_treasury_vault () in
      let fees = {
        to_send = 0mutez;
        to_refund = 0mutez;
        payer = redeem_address;
        recipient = storage.fee_recipient;
      } in
      let fees, updated_ubots, updated_batch_set,  payout_token_map = Ubots.collect_redemption_payouts redeem_address fees storage in
      let operations = Treasury_Utils.transfer_holdings treasury_vault redeem_address payout_token_map in
      let operations = resolve_fees fees operations in
      let updated_storage = { storage with user_batch_ordertypes = updated_ubots; batch_set = updated_batch_set;  } in
      (operations, updated_storage)

end

module Token_Utils = struct

[@inline]
let are_equivalent_tokens
  (given: token)
  (test: token) : bool =
    given.token_id = test.token_id &&
    given.name = test.name &&
    given.address = test.address &&
    given.decimals = test.decimals &&
    given.standard = test.standard

[@inline]
let is_valid_swap_pair
  (side: side)
  (swap: swap_reduced)
  (valid_swaps: valid_swaps): swap_reduced =
  let token_pair = Utils.pair_of_swap side swap in
  let rate_name = Utils.get_rate_name_from_pair token_pair in
  if Map.mem rate_name valid_swaps then swap else failwith unsupported_swap_type

[@inline]
let remove_token
  (token: token)
  (valid_tokens: valid_tokens) : valid_tokens =
  match Map.find_opt token.name valid_tokens with
  | Some existing_token -> if are_equivalent_tokens existing_token token then
                             Map.remove token.name valid_tokens
                           else
                             failwith token_already_exists_but_details_are_different
  | None -> valid_tokens

[@inline]
let add_token
  (token: token)
  (valid_tokens: valid_tokens) : valid_tokens =
  match Map.find_opt token.name valid_tokens with
  | Some existing_token -> if are_equivalent_tokens existing_token token then
                             valid_tokens
                           else
                             failwith token_already_exists_but_details_are_different
  | None -> Map.add token.name token valid_tokens

[@inline]
let is_token_used
  (token: token)
  (valid_tokens: valid_tokens) : bool =
  let is_token_in_tokens (acc, (_i, t) : bool * (string * token)) : bool =
    are_equivalent_tokens token t ||
    acc
  in
  Map.fold is_token_in_tokens valid_tokens false

[@inline]
let is_token_used_in_swaps
  (token: token)
  (valid_swaps: valid_swaps)
  (tokens: valid_tokens): bool =
  let is_token_used_in_swap (acc, (_i, valid_swap) : bool * (string * valid_swap_reduced)) : bool =
    let swap = valid_swap.swap in
    let to_token = get_token swap.to tokens in
    let from_token = get_token swap.from tokens in
    are_equivalent_tokens token to_token ||
    are_equivalent_tokens token from_token ||
    acc
  in
  Map.fold is_token_used_in_swap valid_swaps false

[@inline]
let add_swap
  (valid_swap: valid_swap)
  (valid_swaps: valid_swaps) : valid_swaps =
  let swap = valid_swap.swap in
  let swap_reduced = Utils.swap_to_swap_reduced(swap) in
  let rate_name = Utils.get_rate_name_from_swap swap_reduced in
  let valid_swap_reduced = Utils.valid_swap_to_valid_swap_reduced valid_swap in
  Map.add rate_name valid_swap_reduced valid_swaps

[@inline]
let remove_swap
  (valid_swap: valid_swap)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps) : (valid_swaps * valid_tokens) =
  let swap = valid_swap.swap in
  let swap_reduced = Utils.swap_to_swap_reduced(swap) in
  let rate_name = Utils.get_rate_name_from_swap swap_reduced in
  let valid_swaps = Map.remove rate_name valid_swaps in
  let from = get_token swap_reduced.from valid_tokens in
  let to = get_token swap_reduced.to valid_tokens in
  let valid_tokens = if is_token_used_in_swaps from valid_swaps valid_tokens then
                       valid_tokens
                    else
                       remove_token from valid_tokens
  in
  let valid_tokens = if is_token_used_in_swaps to valid_swaps valid_tokens then
                       valid_tokens
                    else
                       remove_token to valid_tokens
  in
  valid_swaps, valid_tokens

end

module Tokens = struct


[@inline]
let validate
  (side: side)
  (swap: swap)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps): swap_reduced =
  let from = swap.from.token in
  let to = swap.to in
  match Map.find_opt from.name valid_tokens with
  | None ->  failwith unsupported_swap_type
  | Some ft -> (match Map.find_opt to.name valid_tokens with
                | None -> failwith unsupported_swap_type
                | Some tt -> if (Token_Utils.are_equivalent_tokens from ft) && (Token_Utils.are_equivalent_tokens to tt) then
                              let sr = Utils.swap_to_swap_reduced swap in
                              Token_Utils.is_valid_swap_pair side sr valid_swaps
                            else
                              failwith unsupported_swap_type)

[@inline]
let check_tokens_size_or_fail
  (tokens_size: nat)
  (limit_on_tokens_or_pairs: nat)
  (num_tokens: nat) : unit =  if tokens_size + num_tokens > limit_on_tokens_or_pairs then failwith upper_limit_on_tokens_has_been_reached else ()

[@inline]
let can_add
  (to: token)
  (from: token)
  (limit_on_tokens_or_pairs: nat)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps): unit =
  let pairs_size = Map.size valid_swaps in
  if pairs_size + 1n > limit_on_tokens_or_pairs then failwith upper_limit_on_swap_pairs_has_been_reached else
  let tokens_size = Map.size valid_tokens in
  let unused_tokens_being_added =
    if Token_Utils.is_token_used to valid_tokens && Token_Utils.is_token_used from valid_tokens then 0n else
    if Token_Utils.is_token_used to valid_tokens || Token_Utils.is_token_used from valid_tokens then 1n else
    2n
  in
  check_tokens_size_or_fail tokens_size limit_on_tokens_or_pairs unused_tokens_being_added

[@inline]
let remove_pair
  (valid_swap: valid_swap)
  (valid_swaps: valid_swaps)
  (valid_tokens: valid_tokens) : valid_swaps * valid_tokens =
  let swap = valid_swap.swap in
  let swap_reduced = Utils.swap_to_swap_reduced swap in
  let rate_name = Utils.get_rate_name_from_swap swap_reduced in
  let rate_found =  Map.find_opt rate_name valid_swaps in
  match rate_found with
  | Some _ -> Token_Utils.remove_swap valid_swap valid_tokens valid_swaps
  | None ->  failwith swap_does_not_exist

[@inline]
let add_pair
  (limit_on_tokens_or_pairs: nat)
  (valid_swap: valid_swap)
  (valid_swaps: valid_swaps)
  (valid_tokens: valid_tokens) : valid_swaps * valid_tokens =
  let swap = valid_swap.swap in
  let from = swap.from.token in
  let to = swap.to in
  let () = can_add to from limit_on_tokens_or_pairs valid_tokens valid_swaps in
  let swap_reduced = Utils.swap_to_swap_reduced swap in
  let rate_name = Utils.get_rate_name_from_swap swap_reduced in
  let rate_found =  Map.find_opt rate_name valid_swaps in
  match rate_found with
  | Some _  -> failwith swap_already_exists
  | None -> let valid_tokens = Token_Utils.add_token from valid_tokens in
                  let valid_tokens = Token_Utils.add_token to valid_tokens in
                  let valid_swaps = Token_Utils.add_swap valid_swap valid_swaps in
                  valid_swaps, valid_tokens


end

module Batch_Utils = struct

type batch_status =
  | Open of { start_time : timestamp }
  | Closed of { start_time : timestamp ; closing_time : timestamp }
  | Cleared of { at : timestamp; clearing : clearing; rate : exchange_rate }


[@inline]
let is_batch_open
  (batch:batch): bool =
  match batch.status with
  | Open _ -> true
  | _ -> false


[@inline]
let reduce_volumes
  (ots: ordertypes)
  (volumes:volumes): volumes =
  let reduce_volume_for_ot (vols, (ot, amt) : volumes * (ordertype * nat)) : volumes =
    let side = ot.side in
    let tolerance = ot.tolerance in
    match side with
    | Buy -> let total_buy_side_volume = abs(vols.buy_total_volume - amt)
             in
             (match tolerance with
              | Minus -> { vols with buy_minus_volume = abs(vols.buy_minus_volume - amt); buy_total_volume = total_buy_side_volume; }
              | Exact -> { vols with buy_exact_volume = abs(vols.buy_exact_volume - amt);  buy_total_volume = total_buy_side_volume; }
              | Plus -> { vols with buy_plus_volume = abs(vols.buy_plus_volume - amt);  buy_total_volume = total_buy_side_volume; })
    | Sell -> let total_sell_side_volume = abs(vols.sell_total_volume - amt)
              in
              (match tolerance with
               | Minus -> { vols with sell_minus_volume = abs(vols.sell_minus_volume - amt); sell_total_volume = total_sell_side_volume; }
               | Exact -> { vols with sell_exact_volume = abs(vols.sell_exact_volume - amt);  sell_total_volume = total_sell_side_volume; }
               | Plus -> { vols with sell_plus_volume = abs(vols.sell_plus_volume - amt);  sell_total_volume = total_sell_side_volume; })
  in
  Map.fold reduce_volume_for_ot ots volumes


[@inline]
let set_buy_side_volume
  (order: swap_order)
  (volumes : volumes) : volumes =
  let total_buy_side_volume = volumes.buy_total_volume + order.swap.from.amount in
  match order.tolerance with
  | Minus -> { volumes with buy_minus_volume = volumes.buy_minus_volume + order.swap.from.amount; buy_total_volume = total_buy_side_volume; }
  | Exact -> { volumes with buy_exact_volume = volumes.buy_exact_volume + order.swap.from.amount;  buy_total_volume = total_buy_side_volume; }
  | Plus -> { volumes with buy_plus_volume = volumes.buy_plus_volume + order.swap.from.amount;  buy_total_volume = total_buy_side_volume; }

[@inline]
let set_sell_side_volume
  (order: swap_order)
  (volumes : volumes) : volumes =
 let total_sell_side_volume = volumes.sell_total_volume + order.swap.from.amount in
  match order.tolerance with
  | Minus -> { volumes with sell_minus_volume = volumes.sell_minus_volume + order.swap.from.amount; sell_total_volume = total_sell_side_volume; }
  | Exact -> { volumes with sell_exact_volume = volumes.sell_exact_volume + order.swap.from.amount;  sell_total_volume = total_sell_side_volume; }
  | Plus -> { volumes with sell_plus_volume = volumes.sell_plus_volume + order.swap.from.amount;  sell_total_volume = total_sell_side_volume; }

[@inline]
let make
  (batch_number: nat)
  (timestamp: timestamp)
  (pair: pair) : batch =
  let volumes: volumes = {
      buy_minus_volume = 0n;
      buy_exact_volume = 0n;
      buy_plus_volume = 0n;
      buy_total_volume = 0n;
      sell_minus_volume = 0n;
      sell_exact_volume = 0n;
      sell_plus_volume = 0n;
      sell_total_volume = 0n;
    } in
  {
    batch_number= batch_number;
    status = Open { start_time = timestamp } ;
    pair = pair;
    volumes = volumes;
    holdings = 0n;
  }

[@inline]
let update_current_batch_in_set
  (batch : batch)
  (batch_set : batch_set) : (batch * batch_set)=
  let updated_batches = Big_map.update batch.batch_number (Some batch) batch_set.batches in
  let name = Utils.get_rate_name_from_pair batch.pair in
  let updated_batch_indices = Map.update name (Some batch.batch_number) batch_set.current_batch_indices in
  batch, { batch_set with batches = updated_batches; current_batch_indices = updated_batch_indices; }

[@inline]
let should_be_cleared
  (batch : batch)
  (current_time : timestamp) : bool =
  match batch.status with
    | Closed { start_time = _; closing_time } ->
      current_time > closing_time + price_wait_window_in_seconds
    | _ -> false


[@inline]
let is_cleared
  (batch: batch) : bool =
  match batch.status with
  | Cleared _ -> true
  | _ -> false

[@inline]
let start_period
  (pair : pair)
  (batch_set : batch_set)
  (current_time : timestamp) : (batch * batch_set) =
  let highest_batch_index = Utils.get_highest_batch_index batch_set.current_batch_indices in
  let new_batch_number = highest_batch_index + 1n in
  let new_batch = make new_batch_number current_time pair in
  update_current_batch_in_set new_batch batch_set

[@inline]
let close
(deposit_time_window: nat)
(batch : batch) : batch =
  match batch.status with
    | Open { start_time } ->
      let batch_close_time = start_time + (int deposit_time_window) in
      let new_status = Closed { start_time = start_time; closing_time = batch_close_time } in
      { batch with status = new_status }
    | _ -> failwith trying_to_close_batch_which_is_not_open

[@inline]
let new_batch_set : batch_set =
  {
    current_batch_indices = (Map.empty: (string, nat) map);
    batches= (Big_map.empty: (nat, batch) big_map);
  }

[@inline]
let progress_batch
  (deposit_time_window: nat)
  (pair: pair)
  (batch: batch)
  (batch_set: batch_set)
  (current_time : timestamp) : (batch * batch_set) =
  match batch.status with
  | Open { start_time } ->
    if  current_time >= start_time + (int deposit_time_window) then
      let closed_batch = close deposit_time_window batch in
      update_current_batch_in_set closed_batch batch_set
    else
      (batch, batch_set)
  | Closed { closing_time =_ ; start_time = _} ->
    (*  Batches can only be cleared on receipt of rate so here they should just be returned *)
    (batch, batch_set)
  | Cleared _ -> start_period pair batch_set current_time


[@inline]
let update_volumes
  (order: swap_order)
  (batch : batch)  : batch =
  let vols = batch.volumes in
  let updated_vols = match order.side with
                     | Buy -> set_buy_side_volume order vols
                     | Sell -> set_sell_side_volume order vols
  in
  { batch with volumes = updated_vols;  }


[@inline]
let can_deposit
  (batch:batch) : bool =
  match batch.status with
  | Open _ -> true
  | _ -> false


[@inline]
let can_be_finalized
  (batch : batch)
  (current_time : timestamp) : bool = should_be_cleared batch current_time

[@inline]
let finalize_batch
  (batch : batch)
  (clearing: clearing)
  (current_time : timestamp)
  (rate : exchange_rate)
  (batch_set : batch_set): batch_set =
  let finalized_batch : batch = {
      batch with status = Cleared {
        at = current_time;
        clearing = clearing;
        rate = rate
      }
    } in
  let _, ucb = update_current_batch_in_set finalized_batch batch_set in
  ucb

[@inline]
let get_current_batch_without_opening
  (deposit_time_window: nat)
  (pair: pair)
  (current_time: timestamp)
  (batch_set: batch_set) : (batch option * batch_set) =
  let current_batch_index = Utils.get_current_batch_index pair batch_set.current_batch_indices in
  match Big_map.find_opt current_batch_index batch_set.batches with
  | None ->  None, batch_set
  | Some cb -> let is_cleared = is_cleared cb in
               if is_cleared then
                 Some cb, batch_set
                else
                 let batch, batch_set = progress_batch deposit_time_window pair cb batch_set current_time in
                 Some batch, batch_set

[@inline]
let get_current_batch
  (deposit_time_window: nat)
  (pair: pair)
  (current_time: timestamp)
  (batch_set: batch_set) : (batch * batch_set) =
  let current_batch_index = Utils.get_current_batch_index pair batch_set.current_batch_indices in
  match Big_map.find_opt current_batch_index batch_set.batches with
  | None ->  start_period pair batch_set current_time
  | Some cb ->  progress_batch deposit_time_window pair cb batch_set current_time

end

module Clearing = struct

(*
 Get the correct exchange rate based on the clearing price
*)
[@inline]
let get_clearing_rate
  (clearing: clearing)
  (exchange_rate: exchange_rate) : exchange_rate =
  match clearing.clearing_tolerance with
  | Exact -> exchange_rate
  | Plus -> let rate = Rational.mul (exchange_rate.rate) ten_bips_constant in
            { exchange_rate with rate = rate}
  | Minus -> let rate = Rational.div (exchange_rate.rate) ten_bips_constant in
             { exchange_rate with rate = rate}

[@inline]
let filter_volumes
  (volumes: volumes)
  (clearing: clearing) : (nat * nat) =
  match clearing.clearing_tolerance with
  | Minus -> let sell_vol = volumes.sell_minus_volume + volumes.sell_exact_volume + volumes.sell_plus_volume in
             volumes.buy_minus_volume , sell_vol
  | Exact -> let buy_vol = volumes.buy_minus_volume + volumes.buy_exact_volume in
             let sell_vol = volumes.sell_exact_volume + volumes.sell_plus_volume in
             buy_vol, sell_vol
  | Plus -> let buy_vol = volumes.buy_minus_volume + volumes.buy_exact_volume + volumes.buy_plus_volume in
            buy_vol, volumes.sell_plus_volume

[@inline]
let compute_equivalent_amount (amount : nat) (rate : exchange_rate) (is_sell_side: bool) : nat =
  let float_amount = Rational.new (int (amount)) in
  if is_sell_side then
    Utils.get_rounded_number_lower_bound (Rational.div float_amount rate.rate)
  else
    Utils.get_rounded_number_lower_bound (Rational.mul float_amount rate.rate)

(*
  This function builds the order equivalence for the pro-rata redeemption.
*)
[@inline]
let build_total_cleared_volumes
  (volumes: volumes)
  (clearing : clearing)
  (rate : exchange_rate) : clearing =
  (* Collect the bid and ask amounts associated with the given clearing level.  Those volumes that are outside the clearing price are excluded *)
  let (buy_amounts_subject_to_clearing, ask_amounts_subject_to_clearing) = filter_volumes volumes clearing in
  (* Find the rate associated with the clearing point *)
  let clearing_rate = get_clearing_rate clearing rate in
  (* Find the volume in buy side units that can be cleared on both sides of the trade *)
  let buy_side_total_cleared_volume = match clearing.clearing_tolerance with
                                      | Minus -> clearing.clearing_volumes.minus
                                      | Exact -> clearing.clearing_volumes.exact
                                      | Plus -> clearing.clearing_volumes.plus
  in
  (* Convert cleared volume to sell side units to assist in payout claculations later *)
  let sell_side_total_cleared_volume_as_rational = Rational.mul (Rational.new (int buy_side_total_cleared_volume)) clearing_rate.rate in
  let sell_side_total_cleared_volume = Utils.get_rounded_number_lower_bound sell_side_total_cleared_volume_as_rational in
  (* Build total volumes objects which represents the TOTAL cleared volume on each side of the swap along which will be used in the payout calculations  *)
  let total_volumes = {
    buy_side_total_cleared_volume = buy_side_total_cleared_volume;
    buy_side_volume_subject_to_clearing = buy_amounts_subject_to_clearing;
    sell_side_total_cleared_volume = sell_side_total_cleared_volume;
    sell_side_volume_subject_to_clearing = ask_amounts_subject_to_clearing;
  } in
  { clearing with total_cleared_volumes = total_volumes; clearing_rate = clearing_rate }

[@inline]
let compute_clearing_prices
  (rate: exchange_rate)
  (current_batch : batch) : clearing =
  let volumes = current_batch.volumes in
  let sell_cp_minus = int (volumes.sell_minus_volume) in
  let sell_cp_exact = int (volumes.sell_exact_volume) in
  let sell_cp_plus = int (volumes.sell_plus_volume) in
  let buy_cp_minus = int (volumes.buy_minus_volume) in
  let buy_cp_exact = int (volumes.buy_exact_volume) in
  let buy_cp_plus = int (volumes.buy_plus_volume) in
  let buy_side : buy_side = buy_cp_minus, buy_cp_exact, buy_cp_plus in
  let sell_side : sell_side = sell_cp_minus, sell_cp_exact, sell_cp_plus in
  let clearing = Utils.get_clearing_price rate buy_side sell_side in
  let with_total_cleared_vols = build_total_cleared_volumes volumes clearing rate in
  with_total_cleared_vols

end

type storage  = Storage.t
type result = operation list * storage

[@inline]
let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
  | Deposit of external_swap_order
  | Tick of string
  | Redeem
  | Cancel of pair
  | Change_fee of tez
  | Change_admin_address of address
  | Change_fee_recipient_address of address
  | Add_token_swap_pair of valid_swap
  | Remove_token_swap_pair of valid_swap
  | Amend_token_and_pair_limit of nat
  | Add_or_update_metadata of metadata_update
  | Remove_metadata of string
  | Enable_swap_pair_for_deposit of string
  | Disable_swap_pair_for_deposit of string
  | Change_oracle_source_of_pair of oracle_source_change
  | Change_deposit_time_window of nat

[@inline]
let get_oracle_price
  (failure_code: nat)
  (valid_swap: valid_swap_reduced) : orace_price_update =
  match Tezos.call_view "getPrice" valid_swap.oracle_asset_name valid_swap.oracle_address with
  | Some opu -> opu
  | None -> failwith failure_code

[@inline]
let reject_if_tez_supplied(): unit =
  if Tezos.get_amount () < 1mutez then () else failwith endpoint_does_not_accept_tez

[@inline]
let is_administrator
  (storage : storage) : unit =
  if Tezos.get_sender () = storage.administrator then () else failwith sender_not_administrator

[@inline]
let admin_and_fee_recipient_address_are_different
  (admin : address)
  (fee_recipient : address ): unit =
  if admin = fee_recipient then failwith admin_and_fee_recipient_address_cannot_be_the_same else ()


[@inline]
let finalize
  (batch : batch)
  (current_time : timestamp)
  (rate : exchange_rate)
  (batch_set : batch_set): batch_set =
  if Batch_Utils.can_be_finalized  batch current_time then
    let current_time = Tezos.get_now () in
    let clearing : clearing = Clearing.compute_clearing_prices rate batch in
    Batch_Utils.finalize_batch batch clearing current_time rate batch_set
  else
    batch_set

[@inline]
let external_to_order
  (order: external_swap_order)
  (order_number: nat)
  (batch_number: nat)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps): swap_order =
  let side = Utils.nat_to_side order.side in
  let tolerance = Utils.nat_to_tolerance order.tolerance in
  let sender = Tezos.get_sender () in
  let converted_order : swap_order =
    {
      order_number = order_number;
      batch_number = batch_number;
      trader = sender;
      swap  = order.swap;
      side = side;
      tolerance = tolerance;
      redeemed = false;
    } in
  let _ = Tokens.validate side order.swap valid_tokens valid_swaps in
  converted_order

[@inline]
let get_valid_swap_reduced
 (pair_name: string)
 (storage : storage) : valid_swap_reduced =
 match Map.find_opt pair_name storage.valid_swaps with
 | Some vswp -> vswp
 | None -> failwith swap_does_not_exist

[@inline]

let remove_orders_from_batch
  (ots: ordertypes)
  (batch: batch): batch =
  let volumes = Batch_Utils.reduce_volumes ots batch.volumes in
  { batch with volumes = volumes}

[@inline]
let remove_orders
  (ot: ordertypes)
  (batch:batch)
  (batch_set: batch_set)
  (storage: storage) =
  let batch = remove_orders_from_batch ot batch in
  let batches =  Big_map.update batch.batch_number (Some batch) batch_set.batches in
  let batch_set = { batch_set with batches = batches } in
  let storage = {storage with batch_set = batch_set} in
  storage

[@inline]
let remove_order_types
  (batch_number: nat)
  (holder: address)
  (bot: batch_ordertypes)
  (storage:storage) : ordertypes * storage =
  match Map.find_opt batch_number bot with
  | None -> failwith no_orders_for_user_address
  | Some ots -> let bot = Map.remove batch_number bot in
                let ubots = Big_map.update holder (Some bot) storage.user_batch_ordertypes in
                let storage = { storage with user_batch_ordertypes = ubots;} in
                (ots,storage)

[@inline]
let refund_orders
  (refund_address: address)
  (ots: ordertypes)
  (valid_swap:valid_swap)
  (storage: storage): result =
  let fee = storage.fee_in_mutez in
  let collect_refunds ((tam,mutez_to_ref), (ot, amt): ((token_amount_map * tez) * (ordertype * nat))) : (token_amount_map * tez) =
    let token  = match ot.side with
                 | Buy -> valid_swap.swap.from.token
                 | Sell -> valid_swap.swap.to
    in
    let ta = {
       token = token;
       amount = amt;
    } in
    let tam = TokenAmountMap.increase ta tam in
    let mutez_to_ref = mutez_to_ref + fee in
    tam, mutez_to_ref
  in
  let token_refunds, tez_refunds= Map.fold collect_refunds ots ((Map.empty: token_amount_map), 0mutez) in
  let treasury_vault = Treasury.get_treasury_vault () in
  let operations = Treasury_Utils.transfer_holdings treasury_vault refund_address token_refunds in
  let operations = if tez_refunds > 0mutez then Treasury_Utils.transfer_fee storage.fee_recipient tez_refunds :: operations else operations in
  operations, storage

[@inline]
let cancel_order
  (pair: pair)
  (holder: address)
  (valid_swap: valid_swap)
  (storage: storage) : result =
  let ubots = storage.user_batch_ordertypes in
  let current_time = Tezos.get_now () in
  let (batch, batch_set) = Batch_Utils.get_current_batch storage.deposit_time_window_in_seconds pair current_time storage.batch_set in
  let () = if not (Batch_Utils.is_batch_open batch) then failwith cannot_cancel_orders_for_a_batch_that_is_not_open in
  match Big_map.find_opt holder ubots with
  | None -> failwith no_orders_for_user_address
  | Some bot -> let orders_to_remove, storage = remove_order_types batch.batch_number holder bot storage in
                let storage = remove_orders orders_to_remove batch batch_set storage in
                refund_orders holder orders_to_remove valid_swap storage

[@inline]
let cancel
  (pair: pair)
  (storage: storage): result =
  let () = reject_if_tez_supplied () in
  let sender = Tezos.get_sender () in
  let token_one, token_two = pair in
  let pair_name = Utils.find_lexicographical_pair_name token_one token_two in
  match Map.find_opt pair_name storage.valid_swaps with
  | None -> failwith swap_does_not_exist
  | Some vswpr -> let vswp = Utils.valid_swap_reduced_to_valid_swap vswpr 1n storage.valid_tokens in
                  cancel_order pair sender vswp storage

[@inline]
let oracle_price_is_not_stale
  (deposit_time_window: nat)
  (oracle_price_timestamp: timestamp) : unit =
  let dtw_i = int deposit_time_window in
  if (Tezos.get_now () - dtw_i) < oracle_price_timestamp then () else failwith oracle_price_is_stale

[@inline]
let is_oracle_price_newer_than_current
  (rate_name: string)
  (oracle_price_timestamp: timestamp)
  (storage: storage): unit =
  let rates = storage.rates_current in
  match Big_map.find_opt rate_name rates with
  | Some r -> if r.when >=oracle_price_timestamp then failwith oracle_price_is_not_timely
  | None   -> ()


[@inline]
let confirm_oracle_price_is_available_before_deposit
  (pair:pair)
  (batch:batch)
  (storage:storage) : unit =
  if Batch_Utils.is_batch_open batch then () else
  let pair_name = Utils.get_rate_name_from_pair pair in
  let valid_swap_reduced = get_valid_swap_reduced pair_name storage in
  let (lastupdated, _price)  = get_oracle_price oracle_price_should_be_available_before_deposit valid_swap_reduced in
  oracle_price_is_not_stale storage.deposit_time_window_in_seconds lastupdated

[@inline]
let confirm_swap_pair_is_disabled_prior_to_removal
  (valid_swap:valid_swap) : unit =
  if valid_swap.is_disabled_for_deposits then () else failwith cannot_remove_swap_pair_that_is_not_disabled

(* Register a deposit during a valid (Open) deposit time; fails otherwise.
   Updates the current_batch if the time is valid but the new batch was not initialized. *)
[@inline]
let deposit (external_order: external_swap_order) (storage : storage) : result =
  let pair = Utils.pair_of_external_swap external_order in
  let current_time = Tezos.get_now () in
  let pair_name = Utils.get_rate_name_from_pair pair in
  let valid_swap = get_valid_swap_reduced pair_name storage in
  if valid_swap.is_disabled_for_deposits then failwith swap_is_disabled_for_deposits else
  let fee_amount_in_mutez = storage.fee_in_mutez in
  let fee_provided = Tezos.get_amount () in
  if fee_provided < fee_amount_in_mutez then failwith insufficient_swap_fee else
  if fee_provided > fee_amount_in_mutez then failwith more_tez_sent_than_fee_cost else
  let (current_batch, current_batch_set) = Batch_Utils.get_current_batch storage.deposit_time_window_in_seconds pair current_time storage.batch_set in
  if Batch_Utils.can_deposit current_batch then
     let () = confirm_oracle_price_is_available_before_deposit pair current_batch storage in
     let storage = { storage with batch_set = current_batch_set } in
     let current_batch_number = current_batch.batch_number in
     let next_order_number = storage.last_order_number + 1n in
     let order : swap_order = external_to_order external_order next_order_number current_batch_number storage.valid_tokens storage.valid_swaps in
     (* We intentionally limit the amount of distinct orders that can be placed whilst unredeemed orders exist for a given user  *)
     if Ubots.is_within_limit order.trader storage.user_batch_ordertypes then
       let updated_volumes = Batch_Utils.update_volumes order current_batch in
       let updated_batches = Big_map.update current_batch_number (Some updated_volumes) current_batch_set.batches in
       let updated_batches = BatchHoldings_Utils.add_batch_holding current_batch_number order.trader storage.user_batch_ordertypes updated_batches in
       let new_ubot = Ubots.add_order order.trader current_batch_number order storage.user_batch_ordertypes in
       let updated_batch_set = { current_batch_set with batches = updated_batches } in
       let updated_storage = {
         storage with batch_set = updated_batch_set;
         last_order_number = next_order_number;
         user_batch_ordertypes = new_ubot; } in
       let treasury_ops = Treasury.deposit order.trader order.swap.from in
       (treasury_ops, updated_storage)

      else
        failwith too_many_unredeemed_orders
  else
    failwith no_open_batch

[@inline]
let redeem
 (storage : storage) : result =
  let holder = Tezos.get_sender () in
  let () = reject_if_tez_supplied () in
  let (tokens_transfer_ops, new_storage) = Treasury.redeem holder storage in
  (tokens_transfer_ops, new_storage)

[@inline]
let convert_oracle_price
  (precision: nat)
  (swap: swap)
  (lastupdated: timestamp)
  (price: nat)
  (tokens: valid_tokens): exchange_rate =
  let prc,den : nat * int =  if swap.from.token.decimals > precision then
                               let diff:int = swap.from.token.decimals - precision in
                               let diff_pow = Utils.pow 10 diff in
                               let adj_price = Utils.to_nat (price * diff_pow) in
                               let denom  = Utils.pow 10 (int swap.from.token.decimals) in
                               (adj_price, denom)
                             else
                               let denom = Utils.pow 10 (int precision) in
                               (price, denom)
  in
  let rational_price = Rational.new (int prc) in
  let rational_denom = Rational.new den in
  let rational_rate: Rational.t = Rational.div rational_price rational_denom in
  let swap_reduced: swap_reduced = Utils.swap_to_swap_reduced swap in
  let rate = {
   swap = swap_reduced;
   rate = rational_rate;
   when = lastupdated;
  } in
  Utils.scale_on_receive_for_token_precision_difference rate tokens

[@inline]
let change_oracle_price_source
  (source_change: oracle_source_change)
  (storage: storage) : result =
  let _ = is_administrator storage in
  let () = reject_if_tez_supplied () in
   let valid_swap_reduced = get_valid_swap_reduced source_change.pair_name storage in
  let valid_swap = { valid_swap_reduced with oracle_address = source_change.oracle_address; oracle_asset_name = source_change.oracle_asset_name; oracle_precision = source_change.oracle_precision;  } in
  let _ = get_oracle_price unable_to_get_price_from_new_oracle_source valid_swap_reduced in
  let updated_swaps = Map.update source_change.pair_name (Some valid_swap) storage.valid_swaps in
  let storage = { storage with valid_swaps = updated_swaps} in
  no_op (storage)

[@inline]
let tick_price
  (rate_name: string)
  (valid_swap : valid_swap)
  (storage : storage) : storage =
  let valid_swap_reduced = Utils.valid_swap_to_valid_swap_reduced valid_swap in
  let (lastupdated, price) = get_oracle_price unable_to_get_price_from_oracle valid_swap_reduced in
  let () = is_oracle_price_newer_than_current rate_name lastupdated storage in
  let () = oracle_price_is_not_stale storage.deposit_time_window_in_seconds lastupdated in
  let oracle_rate = convert_oracle_price valid_swap.oracle_precision valid_swap.swap lastupdated price storage.valid_tokens in
  let storage = Utils.update_current_rate (rate_name) (oracle_rate) (storage) in
  let pair = Utils.pair_of_rate oracle_rate in
  let current_time = Tezos.get_now () in
  let batch_set = storage.batch_set in
  let (batch_opt, batch_set) = Batch_Utils.get_current_batch_without_opening storage.deposit_time_window_in_seconds pair current_time batch_set in
  match batch_opt with
  | Some b -> let batch_set = finalize b current_time oracle_rate batch_set in
              let storage = { storage with batch_set = batch_set } in
              storage
  | None ->   storage


[@inline]
let tick
 (rate_name: string)
 (storage : storage) : result =
 let () = reject_if_tez_supplied () in
 match Map.find_opt rate_name storage.valid_swaps with
 | Some vswpr -> let vswp = Utils.valid_swap_reduced_to_valid_swap vswpr 1n storage.valid_tokens in
                let storage = tick_price rate_name vswp storage in
                no_op (storage)
 | None -> failwith swap_does_not_exist

[@inline]
let change_fee
    (new_fee: tez)
    (storage: storage) : result =
    let () = is_administrator storage in
    let () = reject_if_tez_supplied () in
    let storage = { storage with fee_in_mutez = new_fee; } in
    no_op storage

[@inline]
let change_admin_address
    (new_admin_address: address)
    (storage: storage) : result =
    let () = is_administrator storage in
    let () = reject_if_tez_supplied () in
    let () = admin_and_fee_recipient_address_are_different new_admin_address storage.fee_recipient in
    let storage = { storage with administrator = new_admin_address; } in
    no_op storage

[@inline]
let change_fee_recipient_address
    (new_fee_recipient_address: address)
    (storage: storage) : result =
    let () = is_administrator storage in
    let () = reject_if_tez_supplied () in
    let () = admin_and_fee_recipient_address_are_different new_fee_recipient_address storage.administrator in
    let storage = { storage with fee_recipient = new_fee_recipient_address; } in
    no_op storage

[@inline]
let add_token_swap_pair
  (valid_swap: valid_swap)
  (storage: storage) : result =
   let () = is_administrator storage in
   let () = reject_if_tez_supplied () in
   if valid_swap.swap.from.token.decimals < minimum_precision then failwith swap_precision_is_less_than_minimum else
   if valid_swap.swap.to.decimals < minimum_precision then failwith swap_precision_is_less_than_minimum else
   if valid_swap.oracle_precision <> minimum_precision then failwith oracle_must_be_equal_to_minimum_precision else
   let (u_swaps,u_tokens) = Tokens.add_pair storage.limit_on_tokens_or_pairs valid_swap storage.valid_swaps storage.valid_tokens in
   let storage = { storage with valid_swaps = u_swaps; valid_tokens = u_tokens; } in
   no_op storage

[@inline]
let remove_token_swap_pair
  (swap: valid_swap)
  (storage: storage) : result =
   let () = is_administrator storage in
   let () = reject_if_tez_supplied () in
   let () = confirm_swap_pair_is_disabled_prior_to_removal swap in
   let (u_swaps,u_tokens) = Tokens.remove_pair swap storage.valid_swaps storage.valid_tokens in
   let storage = { storage with valid_swaps = u_swaps; valid_tokens = u_tokens; } in
   no_op storage

[@inline]
let add_or_update_metadata
  (metadata_update: metadata_update)
  (storage:storage) : result =
   let () = is_administrator storage in
   let () = reject_if_tez_supplied () in
  let updated_metadata = match Big_map.find_opt metadata_update.key storage.metadata with
                         | None -> Big_map.add metadata_update.key metadata_update.value storage.metadata
                         | Some _ -> Big_map.update metadata_update.key (Some metadata_update.value) storage.metadata
  in
  let storage = {storage with metadata = updated_metadata } in
  no_op storage

[@inline]
let remove_metadata
  (key: string)
  (storage:storage) : result =
   let () = is_administrator storage in
   let () = reject_if_tez_supplied () in
  let updated_metadata = Big_map.remove key storage.metadata in
  let storage = {storage with metadata = updated_metadata } in
  no_op storage

[@inline]
let set_deposit_status
  (pair_name: string)
  (disabled: bool)
  (storage: storage) : result =
   let () = is_administrator storage in
   let () = reject_if_tez_supplied () in
   let valid_swap = get_valid_swap_reduced pair_name storage in
   let valid_swap = { valid_swap with is_disabled_for_deposits = disabled; } in
   let valid_swaps = Map.update pair_name (Some valid_swap) storage.valid_swaps in
   let storage = { storage with valid_swaps = valid_swaps; } in
   no_op (storage)

[@inline]
let amend_token_and_pair_limit
  (limit: nat)
  (storage: storage) : result =
  let () = is_administrator storage in
  let () = reject_if_tez_supplied () in
  let token_count = Map.size storage.valid_tokens in
  let pair_count =  Map.size storage.valid_swaps in
  if limit < token_count then failwith cannot_reduce_limit_on_tokens_to_less_than_already_exists else
  if limit < pair_count then failwith cannot_reduce_limit_on_swap_pairs_to_less_than_already_exists else
  let storage = { storage with limit_on_tokens_or_pairs = limit} in
  no_op (storage)

[@inline]
let change_deposit_time_window
  (new_window: nat)
  (storage: storage) : result =
  let () = is_administrator storage in
  let () = reject_if_tez_supplied () in
  if new_window < minimum_deposit_time_in_seconds then failwith cannot_update_deposit_window_to_less_than_the_minimum else
  if new_window > maximum_deposit_time_in_seconds then failwith cannot_update_deposit_window_to_more_than_the_maximum else
  let storage = { storage with deposit_time_window_in_seconds = new_window; } in
  no_op storage

[@view]
let get_fee_in_mutez ((), storage : unit * storage) : tez = storage.fee_in_mutez

[@view]
let get_valid_swaps ((), storage : unit * storage) : valid_swaps = storage.valid_swaps

[@view]
let get_valid_tokens ((), storage : unit * storage) : valid_tokens = storage.valid_tokens

[@view]
let get_current_batches ((),storage: unit * storage) : batch list=
  let collect_batches (acc, (_s, i) :  batch list * (string * nat)) : batch list =
     match Big_map.find_opt i storage.batch_set.batches with
     | None   -> acc
     | Some b -> b :: acc
    in
    Map.fold collect_batches storage.batch_set.current_batch_indices []


let main
  (action, storage : entrypoint * storage) : operation list * storage =
  match action with
  (* User endpoints *)
   | Deposit order -> deposit order storage
   | Redeem -> redeem storage
   | Cancel pair -> cancel pair storage
  (* Maintenance endpoint *)
   | Tick r ->  tick r storage
  (* Admin endpoints *)
   | Change_fee new_fee -> change_fee new_fee storage
   | Change_admin_address new_admin_address -> change_admin_address new_admin_address storage
   | Change_fee_recipient_address new_fee_recipient_address -> change_fee_recipient_address new_fee_recipient_address storage
   | Add_token_swap_pair valid_swap -> add_token_swap_pair valid_swap storage
   | Remove_token_swap_pair valid_swap -> remove_token_swap_pair valid_swap storage
   | Change_oracle_source_of_pair source_update -> change_oracle_price_source source_update storage
   | Amend_token_and_pair_limit l -> amend_token_and_pair_limit l storage
   | Add_or_update_metadata mu -> add_or_update_metadata mu storage
   | Remove_metadata k -> remove_metadata k storage
   | Enable_swap_pair_for_deposit pair_name -> set_deposit_status pair_name false storage
   | Disable_swap_pair_for_deposit pair_name -> set_deposit_status pair_name true storage
   | Change_deposit_time_window t -> change_deposit_time_window t storage


