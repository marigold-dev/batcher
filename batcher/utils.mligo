#import "types.mligo" "Types"
#import "errors.mligo" "Errors"
#import "constants.mligo" "Constants"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"

type buy_side = Types.buy_side
type sell_side = Types.sell_side
type token = Types.token
type valid_tokens = Types.valid_tokens
type swap = Types.swap
type swap_reduced = Types.swap_reduced
type valid_swap = Types.valid_swap
type valid_swap_reduced = Types.valid_swap_reduced
type total_cleared_volumes = Types.total_cleared_volumes
type tolerance = Types.tolerance
type exchange_rate  = Types.exchange_rate
type clearing = Types.clearing
type side = Types.side
type pair = Types.pair
type batch_indices = Types.batch_indices
type rates_current = Types.rates_current
type external_swap_order = Types.external_swap_order
type token_amount_map = Types.token_amount_map
type token_amount = Types.token_amount
type ordertype = Types.ordertype
type swap_order = Types.swap_order

[@inline]
let get_vault () : address = Tezos.get_self_address ()

[@inline]
let get_token
  (token_name: string)
  (tokens: valid_tokens): token =
  let tok_opt = Map.find_opt token_name tokens in
  match tok_opt with
  | Some t -> t
  | None -> failwith Errors.unable_to_reduce_token_amount_to_less_than_zero

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
  | None -> failwith Errors.number_is_not_a_nat

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
  let right_number = Rational.div (Rational.mul (Rational.new (sell_minus_token + sell_exact_token + sell_plus_token)) Constants.ten_bips_constant) rate in
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
  let right_number = Rational.div (Rational.new (sell_plus_token)) (Rational.mul Constants.ten_bips_constant rate) in
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
    else failwith Errors.unable_to_parse_side_from_external_order

[@inline]
let nat_to_tolerance (tolerance : nat) : tolerance =
  if tolerance = 0n then Minus
  else if tolerance = 1n then Exact
  else if tolerance = 2n then Plus
  else failwith Errors.unable_to_parse_tolerance_from_external_order

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
let update_current_rate (rate_name : string) (rate : exchange_rate) (rates_current : rates_current) =
  update_if_more_recent rate_name rate rates_current

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
  if Tezos.get_amount () < 1mutez then () else failwith Errors.endpoint_does_not_accept_tez

[@inline]
let is_administrator
  (administrator : address) : unit =
  if Tezos.get_sender () = administrator then () else failwith Errors.sender_not_administrator

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
                                                    (failwith Errors.unable_to_reduce_token_amount_to_less_than_zero : nat)
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
      | None -> failwith Errors.invalid_token_address
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
      | None -> failwith Errors.invalid_token_address
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
    if standard = Constants.fa12_token then
      transfer_fa12_token sender receiver token_address token_amount.amount
    else if standard = Constants.fa2_token then
      transfer_fa2_token sender receiver token_address token_amount.token.token_id token_amount.amount
    else
      failwith Errors.token_standard_not_found
  | None ->
      failwith Errors.token_standard_not_found

[@inline]
let handle_transfer (sender : address) (receiver : address) (received_token : token_amount) : operation =
  match received_token.token.address with
  | None -> failwith Errors.xtz_not_currently_supported
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
    | None -> failwith Errors.invalid_tezos_address
    | Some rec_address -> Tezos.transaction () amount rec_address


end

