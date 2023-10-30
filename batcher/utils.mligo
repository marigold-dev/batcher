#include "./types.mligo" 
#include "./errors.mligo"
#include "./constants.mligo"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"


[@inline]
let no_op (type storage) (s : storage) : operation list * storage =  (([] : operation list), s)

[@inline]
let get_vault () : address = Tezos.get_self_address ()

[@inline]
let get_token_from_map
  (token_name: string)
  (tokens: ValidTokens.t_map): token =
  let tok_opt = Map.find_opt token_name tokens in
  match tok_opt with
  | Some t -> t
  | None -> failwith unable_to_reduce_token_amount_to_less_than_zero

[@inline]
let get_token
  (token_name: string)
  (tokens: ValidTokens.t): token =
  let tok_opt = ValidTokens.find_opt token_name tokens in
  match tok_opt with
  | Some t -> t
  | None -> failwith unable_to_reduce_token_amount_to_less_than_zero

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
  (tokens: ValidTokens.t_map) : swap =
  let from = get_token_from_map swap_reduced.from tokens in
  let to = get_token_from_map swap_reduced.to tokens in
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
  (tokens: ValidTokens.t_map) : valid_swap =
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
let side_to_nat
  (side:side): nat =
  match side with
  | Buy -> 0n
  | Sell -> 1n

[@inline]
let nat_to_side
(order_side : nat) : side =
  if order_side = 0n then Buy
  else
    if order_side = 1n then Sell
    else failwith unable_to_parse_side_from_external_order

[@inline]
let tolerance_to_nat (tolerance:tolerance) : nat = 
  match tolerance with
  | Minus -> 0n
  | Exact -> 1n
  | Plus-> 2n

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

(** [rev list] should return the same list reversed. *)
let rev1 (type a) (list: a list) : a list =
  List.fold_left (fun (xs, x : a list * a) -> x :: xs) ([] : a list) list

(** [concat a b] concat [a] and [b]. *)
let concat1 (type a) (left: a list) (right: a list) : a list =
  List.fold_right (fun (x, xs: a * a list) -> x :: xs) left right

(** concat two list but preserve order *)
let concatlo (type a) (left: a list) (right: a list) : a list =
  let right_rev = rev1 right in
  let to_rev = List.fold_right (fun (x, xs: a * a list) -> x :: xs) left right_rev in
  rev1 to_rev

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
let update_current_rate (rate_name : string) (rate : exchange_rate) (rates_current : rates_current) =
  update_if_more_recent rate_name rate rates_current

[@inline]
let get_rate_scaling_power_of_10
  (rate : exchange_rate)
  (tokens: ValidTokens.t_map): Rational.t =
  let swap = rate.swap in
  let from_token = get_token_from_map swap.from tokens in
  let to_token = get_token_from_map swap.to tokens in
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
  (tokens: ValidTokens.t_map): exchange_rate =
  let scaling_rate = get_rate_scaling_power_of_10 rate tokens in
  let adjusted_rate = Rational.mul rate.rate scaling_rate in
  { rate with rate = adjusted_rate }


let is_some
    (type a)
    (an_opt: a option): bool = 
    match an_opt with
    | Some _ -> true
    | None -> false

let assert_some_or_fail_with
    (type a)
    (an_opt: a option)
    (error: nat) : a = 
    match an_opt with
    | Some v -> v
    | None -> failwith error

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
let are_equivalent_tokens
  (given: token)
  (test: token) : bool =
    given.token_id = test.token_id &&
    given.name = test.name &&
    given.address = test.address &&
    given.decimals = test.decimals &&
    given.standard = test.standard

[@inline]
let reject_if_tez_supplied(): unit =
  if Tezos.get_amount () < 1mutez then () else failwith endpoint_does_not_accept_tez



type orace_price_update = oracle_price_update

[@inline]
let get_oracle_price
  (failure_code: nat)
  (valid_swap: valid_swap_reduced) : orace_price_update =
  match Tezos.call_view "getPrice" valid_swap.oracle_asset_name valid_swap.oracle_address with
  | Some opu -> opu
  | None -> failwith failure_code



module TokenAmountMap = struct

  type op = Increase | Decrease

  let new = (Map.empty: token_amount_map)

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

module TokenAmount = struct

  let recover
  (ot: ordertype)
  (amt: nat)
  (c: clearing)
  (tokens: ValidTokens.t_map): token_amount =
  let swap = c.clearing_rate.swap in
  let token = match ot.side with
             | Buy -> get_token_from_map swap.from tokens
             | Sell -> get_token_from_map swap.to tokens
  in
  {
    token = token;
    amount = amt;
  }
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


[@inline]
let add_token_amounts
  (base_token_amount: token_amount)
  (to_add: token_amount) : token_amount =
  if are_equivalent_tokens base_token_amount.token  to_add.token then
    let new_amount = base_token_amount.amount + to_add.amount in
    {base_token_amount with amount = new_amount;}
  else
    failwith token_already_exists_but_details_are_different

[@inline]
let subtract_token_amounts
  (base_token_amount: token_amount)
  (to_subtract: token_amount) : token_amount =
  if are_equivalent_tokens base_token_amount.token  to_subtract.token then
    let new_int_amount = base_token_amount.amount - to_subtract.amount in
    if new_int_amount < 0 then failwith unable_to_reduce_token_amount_to_less_than_zero else
    {base_token_amount with amount = abs (new_int_amount);}
  else
    failwith token_already_exists_but_details_are_different

[@inline]
let has_redeemable_holdings
  (batcher: address) : bool =
  match Tezos.call_view "redeemable_holdings_available" () batcher with
  | None -> failwith unable_to_call_on_chain_view
  | Some has -> has

[@inline]
let has_token_standard
  (token:token)
  (standard: string): bool = 
  match token.standard with
  | None  -> false
  | Some s  -> s = standard

[@inline]
let approve_fa2_token_transfer
  (order: external_swap_order)
  (token_address:address)
  (batcher: address): operation =
  let contract = Tezos.get_self_address () in
  let add_operator = match Tezos.get_entrypoint_opt "%add_operator" token_address with
                     | Some ep -> ep
                     | None -> failwith entrypoint_does_not_exist
  in
  let param = { 
     owner = contract; 
     operator = batcher; 
     token_id = order.swap.from.token.token_id; } in
  Tezos.transaction param 0mutez add_operator

[@inline]
let approve_fa12_token_transfer
  (order: external_swap_order)
  (token_address:address)
  (batcher:address): operation =
  let approve = match Tezos.get_entrypoint_opt "%approve" token_address with
                | Some ep -> ep
                | None -> failwith entrypoint_does_not_exist
  in
  let param = { 
     spender = batcher;
     value = order.swap.from.amount; } in
  Tezos.transaction param 0mutez approve

[@inline]
let approve_token_transfer
  (order: external_swap_order)
  (token_address:address)
  (batcher:address): operation = 
  if has_token_standard order.swap.from.token fa12_token then
    approve_fa12_token_transfer order token_address batcher 
  else if has_token_standard order.swap.from.token fa2_token then
    approve_fa2_token_transfer order token_address batcher 
  else
    failwith token_standard_not_found



[@inline]
let revoke_fa2_token_transfer
  (order: external_swap_order)
  (token_address:address)
  (batcher: address): operation =
  let contract = Tezos.get_self_address () in
  let remove_operator = match Tezos.get_entrypoint_opt "%remove_operator" token_address with
                        | Some ep -> ep
                        | None -> failwith entrypoint_does_not_exist
  in 
  let param = { 
     owner = contract; 
     operator = batcher; 
     token_id = order.swap.from.token.token_id; } in
  Tezos.transaction param 0mutez remove_operator

[@inline]
let revoke_token_transfer
  (order: external_swap_order)
  (token_address:address)
  (batcher:address): operation option =
  if has_token_standard order.swap.from.token fa12_token then 
    (None:operation option)
  else if has_token_standard order.swap.from.token fa2_token then 
    Some (revoke_fa2_token_transfer order token_address batcher)
  else
    failwith token_standard_not_found

[@inline]
let deposit_to_contract
  (order: external_swap_order)
  (batcher:address): operation = 
  let deposit = match Tezos.get_entrypoint_opt "%deposit" batcher with
                | Some ep -> ep
                | None -> failwith entrypoint_does_not_exist
  in
  Tezos.transaction order 0mutez deposit

[@inline]
let execute_deposit
  (order:external_swap_order)
  (batcher: address): operation list = 
  match order.swap.from.token.address with
  | None -> failwith xtz_not_currently_supported
  | Some ta -> (let app = approve_token_transfer order ta batcher in
                let dep = deposit_to_contract order batcher in
                match revoke_token_transfer order ta batcher with
                | Some rev -> app :: (dep :: (rev :: []))
                | None ->  app:: (dep :: [] ))

[@inline]
let get_valid_swap_reduced
 (pair_name: string)
 (valid_swaps : ValidSwaps.t) : valid_swap_reduced =
 match ValidSwaps.find_opt pair_name valid_swaps with
 | Some vswp -> vswp
 | None -> failwith swap_does_not_exist
 

module Token_Utils = struct

[@inline]
let is_valid_swap_pair
  (side: side)
  (swap: swap_reduced)
  (valid_swaps: ValidSwaps.t): swap_reduced =
  let token_pair = pair_of_swap side swap in
  let rate_name = get_rate_name_from_pair token_pair in
  if ValidSwaps.mem rate_name valid_swaps then swap else failwith unsupported_swap_type

[@inline]
let is_valid_swap_map_pair
  (side: side)
  (swap: swap_reduced)
  (valid_swaps: ValidSwaps.t_map): swap_reduced =
  let token_pair = pair_of_swap side swap in
  let rate_name = get_rate_name_from_pair token_pair in
  if Map.mem rate_name valid_swaps then swap else failwith unsupported_swap_type

[@inline]
let remove_token
  (token: token)
  (valid_tokens: ValidTokens.t) : ValidTokens.t =
  match ValidTokens.find_opt token.name valid_tokens with
  | Some existing_token -> if are_equivalent_tokens existing_token token then
                             ValidTokens.remove token.name valid_tokens
                           else
                             failwith token_already_exists_but_details_are_different
  | None -> valid_tokens

[@inline]
let add_token
  (token: token)
  (valid_tokens: ValidTokens.t) : ValidTokens.t =
  match ValidTokens.find_opt token.name valid_tokens with
  | Some existing_token -> if are_equivalent_tokens existing_token token then
                             valid_tokens
                           else
                             failwith token_already_exists_but_details_are_different
  | None -> ValidTokens.upsert token.name token valid_tokens

[@inline]
let is_token_used
  (token: token)
  (valid_tokens: ValidTokens.t) : bool =
  let is_token_in_tokens (acc, (_i, t) : bool * (string * token)) : bool =
    are_equivalent_tokens token t ||
    acc
  in
  ValidTokens.fold is_token_in_tokens valid_tokens false

[@inline]
let is_token_used_in_swaps
  (token: token)
  (valid_swaps: ValidSwaps.t)
  (tokens: ValidTokens.t): bool =
  let is_token_used_in_swap (acc, (_i, valid_swap) : bool * (string * valid_swap_reduced)) : bool =
    let swap = valid_swap.swap in
    let to_token = get_token swap.to tokens in
    let from_token = get_token swap.from tokens in
    are_equivalent_tokens token to_token ||
    are_equivalent_tokens token from_token ||
    acc
  in
  ValidSwaps.fold is_token_used_in_swap valid_swaps false

[@inline]
let add_swap
  (valid_swap: valid_swap)
  (valid_swaps: ValidSwaps.t) : ValidSwaps.t =
  let swap = valid_swap.swap in
  let swap_reduced = swap_to_swap_reduced(swap) in
  let rate_name = get_rate_name_from_swap swap_reduced in
  let valid_swap_reduced = valid_swap_to_valid_swap_reduced valid_swap in
  ValidSwaps.upsert rate_name valid_swap_reduced valid_swaps

[@inline]
let remove_swap
  (valid_swap: valid_swap)
  (valid_tokens: ValidTokens.t)
  (valid_swaps: ValidSwaps.t) : (ValidSwaps.t * ValidTokens.t) =
  let swap = valid_swap.swap in
  let swap_reduced = swap_to_swap_reduced(swap) in
  let rate_name = get_rate_name_from_swap swap_reduced in
  let valid_swaps = ValidSwaps.remove rate_name valid_swaps in
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
let validate_from_map
  (side: side)
  (swap: swap)
  (valid_tokens: ValidTokens.t_map)
  (valid_swaps: ValidSwaps.t_map): swap_reduced =
  let from = swap.from.token in
  let to = swap.to in
  match Map.find_opt from.name valid_tokens with
  | None ->  failwith unsupported_swap_type
  | Some ft -> (match Map.find_opt to.name valid_tokens with
                | None -> failwith unsupported_swap_type
                | Some tt -> if (are_equivalent_tokens from ft) && (are_equivalent_tokens to tt) then
                              let sr = swap_to_swap_reduced swap in
                              Token_Utils.is_valid_swap_map_pair side sr valid_swaps
                            else
                              failwith unsupported_swap_type)

[@inline]
let validate
  (side: side)
  (swap: swap)
  (valid_tokens: ValidTokens.t)
  (valid_swaps: ValidSwaps.t): swap_reduced =
  let from = swap.from.token in
  let to = swap.to in
  match ValidTokens.find_opt from.name valid_tokens with
  | None ->  failwith unsupported_swap_type
  | Some ft -> (match ValidTokens.find_opt to.name valid_tokens with
                | None -> failwith unsupported_swap_type
                | Some tt -> if (are_equivalent_tokens from ft) && (are_equivalent_tokens to tt) then
                              let sr = swap_to_swap_reduced swap in
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
  (valid_tokens: ValidTokens.t)
  (valid_swaps: ValidSwaps.t): unit =
  let pairs_size = ValidSwaps.size valid_swaps in
  if pairs_size + 1n > limit_on_tokens_or_pairs then failwith upper_limit_on_swap_pairs_has_been_reached else
  let tokens_size = ValidTokens.size valid_tokens in
  let unused_tokens_being_added =
    if Token_Utils.is_token_used to valid_tokens && Token_Utils.is_token_used from valid_tokens then 0n else
    if Token_Utils.is_token_used to valid_tokens || Token_Utils.is_token_used from valid_tokens then 1n else
    2n
  in
  check_tokens_size_or_fail tokens_size limit_on_tokens_or_pairs unused_tokens_being_added

[@inline]
let remove_pair
  (valid_swap: valid_swap)
  (valid_swaps: ValidSwaps.t)
  (valid_tokens: ValidTokens.t) : ValidSwaps.t * ValidTokens.t =
  let swap = valid_swap.swap in
  let swap_reduced = swap_to_swap_reduced swap in
  let rate_name = get_rate_name_from_swap swap_reduced in
  let rate_found =  ValidSwaps.find_opt rate_name valid_swaps in
  match rate_found with
  | Some _ -> Token_Utils.remove_swap valid_swap valid_tokens valid_swaps
  | None ->  failwith swap_does_not_exist

[@inline]
let add_pair
  (limit_on_tokens_or_pairs: nat)
  (valid_swap: valid_swap)
  (valid_swaps: ValidSwaps.t)
  (valid_tokens: ValidTokens.t) : ValidSwaps.t * ValidTokens.t =
  let swap = valid_swap.swap in
  let from = swap.from.token in
  let to = swap.to in
  let () = can_add to from limit_on_tokens_or_pairs valid_tokens valid_swaps in
  let swap_reduced = swap_to_swap_reduced swap in
  let rate_name = get_rate_name_from_swap swap_reduced in
  let rate_found =  ValidSwaps.find_opt rate_name valid_swaps in
  match rate_found with
  | Some _  -> failwith swap_already_exists
  | None -> let valid_tokens = Token_Utils.add_token from valid_tokens in
                  let valid_tokens = Token_Utils.add_token to valid_tokens in
                  let valid_swaps = Token_Utils.add_swap valid_swap valid_swaps in
                  valid_swaps, valid_tokens


end

module TokenManagerUtils = struct

[@inline]
let get_valid_tokens
  (tokenmanager: address) : ValidTokens.t_map = 
  match Tezos.call_view "get_valid_tokens" () tokenmanager with
  | Some tokns -> tokns
  | None -> failwith unable_to_get_tokens_from_token_manager

[@inline]
let get_valid_swaps
  (tokenmanager: address) : ValidSwaps.t_map = 
  match Tezos.call_view "get_valid_swaps" () tokenmanager with
  | Some swaps -> swaps
  | None -> failwith unable_to_get_swaps_from_token_manager

end

module MarketMakerUtils = struct

[@inline]
let get_current_vaults
  (marketmaker: address) : Vaults.t_map = 
  match Tezos.call_view "get_vaults" () marketmaker with
  | Some vaults -> vaults
  | None -> failwith unable_to_get_vaults_from_marketmaker


end

module BatcherUtils = struct

[@inline]
let get_batches_needing_liquidity
  (batcher:address): batch list = 
  match Tezos.call_view "get_current_batches" () batcher with
  | Some batches -> batches
  | None -> failwith unable_to_get_current_batches_from_batcher

end


module OracleUtils = struct 

[@inline]
let get_oracle_price
  (failure_code: nat)
  (valid_swap: valid_swap_reduced) : orace_price_update =
  match Tezos.call_view "getPrice" valid_swap.oracle_asset_name valid_swap.oracle_address with
  | Some opu -> opu
  | None -> failwith failure_code

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
  (rates: rates_current): unit =
  match Big_map.find_opt rate_name rates with
  | Some r -> if r.when >=oracle_price_timestamp then failwith oracle_price_is_not_timely
  | None   -> ()

[@inline]
let convert_oracle_price
  (precision: nat)
  (swap: swap)
  (lastupdated: timestamp)
  (price: nat)
  (tokens: ValidTokens.t_map): exchange_rate =
  let prc,den : nat * int =  if swap.from.token.decimals > precision then
                               let diff:int = swap.from.token.decimals - precision in
                               let diff_pow = pow 10 diff in
                               let adj_price = to_nat (price * diff_pow) in
                               let denom  = pow 10 (int swap.from.token.decimals) in
                               (adj_price, denom)
                             else
                               let denom = pow 10 (int precision) in
                               (price, denom)
  in
  let rational_price = Rational.new (int prc) in
  let rational_denom = Rational.new den in
  let rational_rate: Rational.t = Rational.div rational_price rational_denom in
  let swap_reduced: swap_reduced = swap_to_swap_reduced swap in
  let rate = {
   swap = swap_reduced;
   rate = rational_rate;
   when = lastupdated;
  } in
  scale_on_receive_for_token_precision_difference rate tokens

end


[@inline]
let get_native_token_from_vault 
  (vault_address: address) : token = 
  match Tezos.call_view "get_native_token_of_vault" () vault_address with
  | Some tokn -> tokn
  | None -> failwith unable_to_get_native_token_from_vault
  
[@inline]
let is_known_sender
  (addr : address)
  (error: nat): unit =
  if Tezos.get_sender () = addr then () else failwith error

[@inline]
let send_liquidity_injection_request
  (liq_request: liquidity_injection_request)
  (vault:address) : operation = 
  let liq_req_ent = match Tezos.get_entrypoint_opt "%injectliquidity" vault with
                | Some ep -> ep
                | None -> failwith entrypoint_does_not_exist
  in
  Tezos.transaction liq_request 0mutez liq_req_ent 
  
[@inline]
let send_add_reward
  (amount: tez)
  (vault:address) : operation = 
  let rew_req_ent = match Tezos.get_entrypoint_opt "%addreward" vault with
                | Some ep -> ep
                | None -> failwith entrypoint_does_not_exist
  in
  Tezos.transaction amount amount rew_req_ent 


[@inline]
let entrypoints_exist
   (callback: address)
   (token_fa12_addr: address)  
   (token_fa2_addr: address) : bool * bool * bool * bool = 
   let bo_fa2_opt: balance_of contract option = Tezos.get_entrypoint_opt "%balance_of" token_fa2_addr in
   let cb_fa2_opt: balance_of_response contract option  = Tezos.get_entrypoint_opt "%balance_response_fa2" callback in
   let bo_fa12_opt: get_balance_request contract option = Tezos.get_entrypoint_opt "%getbalance" token_fa12_addr in
   let cb_fa12_opt: nat contract option = Tezos.get_entrypoint_opt "%balance_response_fa12" callback in
   (is_some bo_fa2_opt),(is_some cb_fa2_opt),(is_some bo_fa12_opt),(is_some cb_fa12_opt)


[@inline]
 let getfa2tokenbalance
   (owner: address)
   (callback: address)
   (token_id: nat)
   (token_addr: address) : operation = 
   let balance_req = {
      owner= owner;
      token_id = token_id;
   } in
   let bo_opt = Tezos.get_entrypoint_opt "%balance_of" token_addr in
   let cb_opt : balance_of_response list contract option = Tezos.get_entrypoint_opt "%balance_response_fa2" callback in
   match cb_opt,bo_opt with
   | None, _ -> failwith unable_to_get_balance_response_fa2_entrypoint_from_vault
   | _, None -> failwith unable_to_get_balance_of_entrypoint_from_fa2_token
   | Some cb, Some bo -> let bp = {
                          requests = [ balance_req ];
                          callback = cb;
                          } in
                          Tezos.transaction bp 0mutez bo 

[@inline]
 let getfa12tokenbalance
   (owner: address)
   (callback: address)
   (token_addr: address) : operation =
   let bo_opt = Tezos.get_entrypoint_opt "%getbalance" token_addr in
   let cb_opt: nat contract option = Tezos.get_entrypoint_opt "%balance_response_fa12" callback in
   match cb_opt,bo_opt with
   | None, _ -> failwith unable_to_get_balance_response_fa12_entrypoint_from_vault
   | _, None -> failwith unable_to_get_get_balance_entrypoint_from_fa12_token
   | Some cb, Some bo -> let br = {
                          owner = owner;
                          callback = cb;
                          } in
                          Tezos.transaction br 0mutez bo 


 [@inline]
 let gettokenbalance
   (owner: address)
   (callback: address)
   (token_id: nat)
   (token_addr_opt: address option)
   (token_standard_opt: string option) : operation =
   let token_addr = assert_some_or_fail_with token_addr_opt invalid_token_address in
   let token_standard = assert_some_or_fail_with token_standard_opt token_standard_not_found in
   if token_standard = "FA1.2 token" then getfa12tokenbalance owner callback token_addr else
   if token_standard = "FA2 token" then getfa2tokenbalance owner callback token_id token_addr else
   failwith token_standard_not_found
