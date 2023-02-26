#import "../math_lib/lib/rational.mligo" "Rational"



module Errors = struct

let no_rate_available_for_swap : nat                      = 100n
let invalid_token_address : nat                           = 101n
let invalid_tezos_address : nat                           = 102n
let clearing_level_not_found : nat                        = 103n
let no_open_batch_for_deposits : nat                      = 104n
let batch_should_be_cleared : nat                         = 105n
let trying_to_close_batch_which_is_not_open : nat         = 106n
let unable_to_parse_side_from_external_order : nat        = 107n
let unable_to_parse_tolerance_from_external_order : nat   = 108n
let token_standard_not_found : nat                        = 109n
let xtz_not_currently_supported : nat                     = 110n
let unsupported_swap_type : nat                           = 111n
let unable_to_reduce_token_amount_to_less_than_zero : nat = 112n
let too_many_unredeemed_orders : nat                      = 113n
let insufficient_swap_fee : nat                           = 114n
let sender_not_administrator : nat                        = 115n
let token_already_exists_but_details_are_different: nat   = 116n
let swap_already_exists: nat                              = 117n
let swap_does_not_exist: nat                              = 118n
let inverted_swap_already_exists: nat                     = 119n
let batch_index_does_not_exist_for_specified_pair: nat    = 120n

end

module Constants = struct

(* The constant which represents a 10 basis point difference *)
[@inline] let ten_bips_constant = Rational.div (Rational.new 10001) (Rational.new 10000)

(* The constant which represents the period during which users can deposit, in seconds. *)
[@inline] let deposit_time_window : int = 600

(* The constant which represents the period during which a closed batch will wait before looking for a price, in seconds. *)
[@inline] let price_wait_window : int = 120

[@inline] let fa12_token : string = "FA1.2 token"

[@inline] let fa2_token : string = "FA2 token"

[@inline] let bids : string = "bids"

[@inline] let asks : string = "asks"

[@inline] let open : string = "open"

[@inline] let redeemed : string = "redeemed"

(* Number of seconds after order placement time should the order be removed if it has been redeemed - current default 1 day *)
[@inline] let redeemed_order_removal_time : int = 86400


[@inline] let limit_of_redeemable_items : nat = 10n

end


module Types = struct

  (* Associate alias to token address *)
  type token = {
    name : string;
    address : address option;
    decimals : int;
    standard : string option;
  }

  (* Side of an order, either BUY side or SELL side  *)
  type side =
    [@layout:comb]
    Buy
    | Sell

  (* Tolerance of the order against the oracle price  *)
  type tolerance =
    Plus | Exact | Minus

  (* A token value ascribes an amount to token metadata *)
  type token_amount = {
    token : token;
    amount : nat;
  }

  type token_amount_map = (string, token_amount) map

  type token_holding_map = (address, token_amount_map) map


  (* A token amount 'held' by a specific address *)
  type token_holding = {
    holder: address;
    token_amount : token_amount;
    redeemed: bool;
  }

  type swap = {
   from : token_amount;
   to : token;
  }

  (*I change the type of the rate from tez to nat for sake of simplicity*)
  type exchange_rate = {
    swap : swap;
    rate: Rational.t;
    when : timestamp;
  }

  type swap_order = {
    order_number: nat;
    batch_number: nat;
    trader : address;
    swap  : swap;
    created_at : timestamp;
    side : side;
    tolerance : tolerance;
    redeemed:bool;
  }

  type external_swap_order = {
    swap  : swap;
    created_at : timestamp;
    side : nat;
    tolerance : nat;
  }

  type batch_status  =
    NOT_OPEN | OPEN | CLOSED | FINALIZED

  type prorata_equivalence = {
    buy_side_actual_volume: nat;
    buy_side_actual_volume_equivalence: nat;
    sell_side_actual_volume: nat;
    sell_side_actual_volume_equivalence: nat
  }

  type clearing_volumes = {
    minus: nat;
    exact: nat;
    plus: nat;
  }


  type clearing = {
    clearing_volumes : clearing_volumes;
    clearing_tolerance : tolerance;
    prorata_equivalence: prorata_equivalence;
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

  (*
    A bid : the price a buyer is willing to pay for an asset
    A ask : the price a seller is willing to auxept for an asset
    Here, the orderbook is a map of bids orders list  and asks order list
  *)
  type orderbook = (nat, swap_order) big_map

  type batch_status =
    | Open of { start_time : timestamp }
    | Closed of { start_time : timestamp ; closing_time : timestamp }
    | Cleared of { at : timestamp; clearing : clearing; rate : exchange_rate }


  type volumes = {
    [@layout:comb]
    buy_minus_volume : nat;
    buy_exact_volume : nat;
    buy_plus_volume : nat;
    sell_minus_volume : nat;
    sell_exact_volume : nat;
    sell_plus_volume : nat;
  }

  type pair = token * token

  (* This represents the type of order.  I.e. buy/sell and which level*)
  type ordertype = {
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
  type batch = {
    batch_number: nat;
    status : batch_status;
    volumes : volumes;
    pair : pair;
  }

  type batch_indices = (string,  nat) map

  (* Set of batches, containing the current batch and the previous (finalized) batches.
     The current batch can be open for deposits, closed for deposits (awaiting clearing) or
     finalized, as we wait for a new deposit to start a new batch *)
  type batch_set = {
    current_batch_indices: batch_indices;
    batches: (nat, batch) big_map;
    }
end

module TokenAmount = struct

  type t = Types.token_amount

  let recover
  (ot: Types.ordertype)
  (amt: nat)
  (c: Types.clearing): t =
  let swap = c.clearing_rate.swap in
  let token = match ot.side with
             | Buy -> swap.from.token
             | Sell -> swap.to
  in
  {
    token = token;
    amount = amt;
  }


end

module TokenAmountMap = struct

  type t = Types.token_amount_map

  type op = Increase | Decrease

  let amend
  (ta: Types.token_amount)
  (op: op)
  (tam : t): t =
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
  (ta: Types.token_amount)
  (tam : t): t =
  amend ta Increase tam

  let decrease
  (ta: Types.token_amount)
  (tam: t) : t =
  amend ta Decrease tam

end

module Storage = struct
  (* The tokens that are valid within the contract  *)
  type valid_tokens = (string, Types.token) map

  (* The swaps of valid tokens that are accepted by the contract  *)
  type valid_swaps =  (string, Types.swap) map

  (* The current, most up to date exchange rates between tokens  *)
  type rates_current = (string, Types.exchange_rate) big_map

  type batch = Types.batch

  type batch_set = Types.batch_set

  type user_batch_ordertypes = Types.user_batch_ordertypes

  type t = {
    [@layout:comb]
    valid_tokens : valid_tokens;
    valid_swaps : valid_swaps;
    rates_current : rates_current;
    batch_set : batch_set;
    last_order_number : nat;
    user_batch_ordertypes: user_batch_ordertypes;
    fee_in_mutez: tez;
    fee_recipient : address;
    administrator : address
  }

end

module Utils = struct

type exchange_rate = Types.exchange_rate
type order = Types.swap_order
type batch_set = Types.batch_set
type batch = Types.batch
type rate = Types.exchange_rate

let empty_prorata_equivalence : Types.prorata_equivalence = {
  buy_side_actual_volume = 0n;
  buy_side_actual_volume_equivalence = 0n;
  sell_side_actual_volume = 0n;
  sell_side_actual_volume_equivalence = 0n;
}

[@inline]
let gt (a : Rational.t) (b : Rational.t) : bool = not (Rational.lte a b)

[@inline]
let gte (a : Rational.t) (b : Rational.t) : bool = not (Rational.lt a b)

let pow (base : int) (pow : int) : int =
  let rec iter (acc : int) (rem_pow : int) : int = (if rem_pow = 0 then acc else iter (acc * base) (rem_pow - 1)) in
  iter (1) (pow)

(* Get the number with 0 decimal accuracy *)
let get_rounded_number_lower_bound (number : Rational.t) : nat =
  let zero_decimal_number = Rational.resolve number 0n in
    abs (zero_decimal_number)

let get_min_number (a : Rational.t) (b : Rational.t) =
  if Rational.lte a b then a
  else b

let get_clearing_tolerance (cp_minus : Rational.t) (cp_exact : Rational.t) (cp_plus : Rational.t) : Types.tolerance =
  if (gte cp_minus cp_exact) && (gte cp_minus cp_plus) then Minus
  else if (gte cp_exact cp_minus) && (gte cp_exact cp_plus) then Exact
  else Plus

let get_cp_minus (rate : Rational.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Rational.t =
  let (buy_minus_token, buy_exact_token, buy_plus_token) = buy_side in
  let (sell_minus_token, _, _) = sell_side in
  let left_number = Rational.new (buy_minus_token + buy_exact_token + buy_plus_token)  in
  let right_number = Rational.div (Rational.mul (Rational.new sell_minus_token) Constants.ten_bips_constant) rate in
  let min_number = get_min_number left_number right_number in
  min_number

let get_cp_exact (rate : Rational.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Rational.t =
  let (_, buy_exact_token, buy_plus_token) = buy_side in
  let (sell_minus_token, sell_exact_token, _) = sell_side in
  let left_number = Rational.new (buy_exact_token + buy_plus_token) in
  let right_number = Rational.div (Rational.new (sell_minus_token + sell_exact_token)) rate in
  let min_number = get_min_number left_number right_number in
  min_number

let get_cp_plus (rate : Rational.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Rational.t =
  let (_, _, buy_plus_token) = buy_side in
  let (sell_minus_token, sell_exact_token, sell_plus_token) = sell_side in
  let left_number = Rational.new buy_plus_token in
  let right_number = Rational.div (Rational.new (sell_minus_token + sell_exact_token + sell_plus_token)) (Rational.mul Constants.ten_bips_constant rate) in
  let min_number = get_min_number left_number right_number in
  min_number

let get_clearing_price (exchange_rate : exchange_rate) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Types.clearing =
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
    prorata_equivalence = empty_prorata_equivalence;
    clearing_rate = exchange_rate
  }





  let nat_to_side
  (order_side : nat) : Types.side =
    if order_side = 0n then Buy
    else
      if order_side = 1n then Sell
      else failwith Errors.unable_to_parse_side_from_external_order

  let nat_to_tolerance (tolerance : nat) : Types.tolerance =
    if tolerance = 0n then Minus
    else if tolerance = 1n then Exact
    else if tolerance = 2n then Plus
    else failwith Errors.unable_to_parse_tolerance_from_external_order

  let get_rate_name_from_swap (s : Types.swap) : string =
    let base_name = s.from.token.name in
    let quote_name = s.to.name in
    base_name ^ "/" ^ quote_name

  let get_rate_name_from_pair (s : Types.token * Types.token) : string =
    let (base, quote) = s in
    let base_name = base.name in
    let quote_name = quote.name in
    base_name ^ "/" ^ quote_name

  let get_inverse_rate_name_from_pair (s : Types.token * Types.token) : string =
    let (base, quote) = s in
    let quote_name = quote.name in
    let base_name = base.name in
    quote_name ^ "/" ^ base_name

  let get_rate_name (r : Types.exchange_rate) : string =
    let base_name = r.swap.from.token.name in
    let quote_name = r.swap.to.name in
    base_name ^ "/" ^ quote_name

  let pair_of_swap
    (side: Types.side)
    (swap: Types.swap): (Types.token * Types.token) =
    match side with
    | Buy -> (swap.from.token, swap.to)
    | Sell -> (swap.to, swap.from.token)

  let pair_of_rate (r : Types.exchange_rate) : (Types.token * Types.token) = pair_of_swap Buy r.swap

  let pair_of_external_swap (order : Types.external_swap_order) : (Types.token * Types.token) =
    (* Note:  we assume left-handedness - i.e. direction is buy side*)
    let swap = order.swap in
    let side = nat_to_side order.side in
    pair_of_swap side swap


  let get_token_name_from_token_amount
    (ta : Types.token_amount) : string =
    ta.token.name

  let get_token_name_from_token_holding
    (th : Types.token_holding) : string =
    th.token_amount.token.name

  let assign_new_holder_to_token_holding
    (new_holder : address)
    (token_holding : Types.token_holding) : Types.token_holding =
    { token_holding with holder = new_holder}


  (* Converts a token_amount to a token holding by assigning a holder address *)
  let token_amount_to_token_holding
    (holder : address)
    (token_amount : Types.token_amount)
    (redeemed : bool): Types.token_holding =
    {
      holder =  holder;
      token_amount = token_amount;
      redeemed = redeemed;
    }

   let get_rate_names
     (pair: Types.pair): (string * string) =
     let rate_name = get_rate_name_from_pair pair in
     let inverse_rate_name = get_inverse_rate_name_from_pair pair in
     (rate_name, inverse_rate_name)

   let search_batches
     (rate_name: string)
     (inverse_rate_name: string)
     (batch_indices: Types.batch_indices): (nat option * nat option) =
     let index_found =  Map.find_opt rate_name batch_indices in
     let inv_index_found =  Map.find_opt inverse_rate_name batch_indices in
     (index_found, inv_index_found)

   let get_current_batch_index
     (pair: Types.pair)
     (batch_indices: Types.batch_indices): nat =
     let (rate_name, inverse_rate_name) : string * string = get_rate_names pair in
     let (index_found, inv_index_found) : (nat option * nat option) = search_batches rate_name inverse_rate_name batch_indices in
     match (index_found, inv_index_found) with
     | (Some cbi,_) -> cbi
     | (None, Some cbi) -> cbi
     | (None, None) -> 0n


   let update_batch_index
     (name:string)
     (index: nat)
     (batch_indices:  Types.batch_indices) : Types.batch_indices =
     if Map.mem name batch_indices then
       Map.update name (Some index) batch_indices
     else
       Map.add name index batch_indices


   let set_current_batch_index
     (index: nat)
     (swap: Types.swap)
     (batch_indices: Types.batch_indices): Types.batch_indices =
     let (rate_name, inverse_rate_name) : string * string = get_rate_names (swap.from.token, swap.to) in
     let (index_found, inv_index_found) : (nat option * nat option) = search_batches rate_name inverse_rate_name batch_indices in
     match (index_found, inv_index_found) with
     | (Some _,_) -> update_batch_index rate_name index batch_indices
     | (None, Some _) -> update_batch_index inverse_rate_name index batch_indices
     | (None, None) -> update_batch_index rate_name index batch_indices

  let get_highest_batch_index
    (batch_indices: Types.batch_indices) : nat =
    let return_highest (acc, (_s, i) :  nat * (string * nat)) : nat = if i > acc then
                                                                        i
                                                                      else
                                                                        acc
    in
    Map.fold return_highest batch_indices 0n

  (** [concat a b] concat [a] and [b]. *)
  let concat (type a) (left: a list) (right: a list) : a list =
    List.fold_right (fun (x, xs: a * a list) -> x :: xs) left right

  (** [rev list] should return the same list reversed. *)
  let rev (type a) (list: a list) : a list =
    List.fold_left (fun (xs, x : a list * a) -> x :: xs) ([] : a list) list


  let update_current_rate (rate_name : string) (rate : Types.exchange_rate) (storage : Storage.t) =
    let updated_rates = (match Big_map.find_opt rate_name storage.rates_current with
                          | None -> Big_map.add (rate_name) (rate) storage.rates_current
                          | Some (_p) -> Big_map.update (rate_name) (Some(rate)) (storage.rates_current)) in
    { storage with rates_current = updated_rates }


  let get_rate_scaling_power_of_10 (rate : rate) : Rational.t =
    let from_decimals = rate.swap.from.token.decimals in
    let to_decimals = rate.swap.to.decimals in
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

  let scale_on_post (rate : rate) : rate =
    let scaling_rate = get_rate_scaling_power_of_10 (rate) in
    let adjusted_rate = Rational.mul rate.rate scaling_rate in
    { rate with rate = adjusted_rate }

  let scale_on_get (rate : rate) : rate =
    let scaling_rate = get_rate_scaling_power_of_10 (rate) in
    let adjusted_rate = Rational.div rate.rate scaling_rate in
    { rate with rate = adjusted_rate }

end



module Rates = struct

  type storage = Storage.t
  type rate = Types.exchange_rate
  type swap_order = Types.swap_order
  type token = Types.token

  let post_rate (rate : rate) (storage : storage) : storage =
    let rate_name = Utils.get_rate_name(rate) in
    let scaled_rate = Utils.scale_on_post rate in
    let s = Utils.update_current_rate (rate_name) (scaled_rate) (storage) in
    s

  let get_rate (swap: Types.swap) (storage : storage) : rate =
    let rate_name = Utils.get_rate_name_from_swap swap in
    match Big_map.find_opt rate_name storage.rates_current with
      | None -> (failwith Errors.no_rate_available_for_swap : rate)
      | Some r -> let scaled_rate = Utils.scale_on_get r in
                  scaled_rate

end

module OrderType = struct

type order = Types.swap_order
type ordertype = Types.ordertype
type t = ordertype

let make
    (order: order) : t =
    {
      tolerance = order.tolerance;
      side = order.side;
    }

end

module OrderTypes = struct

type order = Types.swap_order
type ordertypes = Types.ordertypes
type t = ordertypes

let make
    (order: order) : t =
    let ot = OrderType.make order in
    let new_map = (Map.empty : t) in
    Map.add ot order.swap.from.amount new_map

let update
    (order: order)
    (bot: t) : t =
    let ot: OrderType.t = OrderType.make order in
    match Map.find_opt ot bot with
    | None -> Map.add ot order.swap.from.amount bot
    | Some amt -> let new_amt = amt + order.swap.from.amount in
                  Map.update ot (Some new_amt) bot

let count
  (ots: t) : nat = Map.size ots


end

module Batch_OrderTypes = struct

type t = Types.batch_ordertypes
type order = Types.swap_order
type ordertypes = Types.ordertypes

let make
  (batch_id: nat)
  (order: order): t =
  let new_ot : OrderTypes.t  = OrderTypes.make order in
  Map.literal [(batch_id, new_ot)]

let add_or_update
  (batch_id: nat)
  (order: order)
  (bots: t): t =
  match Map.find_opt batch_id bots with
  | None -> let new_ot: OrderTypes.t = OrderTypes.make order in
            let temp: t = Map.add batch_id new_ot bots in
            temp
  | Some bot -> let updated_bot : OrderTypes.t = OrderTypes.update order bot in
                let temp: t = Map.update batch_id (Some updated_bot) bots in
                temp


let count
  (bots: t) : nat =
  let count_aux
    (acc, (_batch_number, ots): nat * (nat * ordertypes)) : nat =
    let ots_count = OrderTypes.count ots in
    acc + ots_count
  in
  Map.fold count_aux bots 0n

end

module Redemption_Utils = struct

type tolerance    = Types.tolerance
type ordertype    = Types.ordertype
type clearing     = Types.clearing
type token        = Types.token
type token_amount = Types.token_amount

  let was_in_clearing_for_buy
   (clearing_tolerance: tolerance)
   (order_tolerance: tolerance) : bool =
      match (order_tolerance, clearing_tolerance) with
      | (Exact,Minus) -> true
      | (Plus,Minus) -> true
      | (Minus,Exact) -> false
      | (Plus,Exact) -> true
      | (Minus,Plus) -> false
      | (Exact,Plus) -> false
      | (_,_) -> true

  let was_in_clearing_for_sell
   (clearing_tolerance: tolerance)
   (order_tolerance: tolerance) : bool =
      match (order_tolerance, clearing_tolerance) with
      | (Exact,Minus) -> false
      | (Plus,Minus) -> false
      | (Minus,Exact) -> true
      | (Plus,Exact) -> false
      | (Minus,Plus) -> true
      | (Exact,Plus) -> true
      | (_,_) -> true

  let was_in_clearing
    (ot: ordertype)
    (clearing: clearing) : bool =
    let order_tolerance = ot.tolerance in
    let order_side = ot.side in
    let clearing_tolerance = clearing.clearing_tolerance in
    match order_side with
    | Buy -> was_in_clearing_for_buy clearing_tolerance order_tolerance
    | Sell -> was_in_clearing_for_sell clearing_tolerance order_tolerance


  let get_clearing_volume
    (clearing:clearing) : nat =
    match clearing.clearing_tolerance with
    | Minus -> clearing.clearing_volumes.minus
    | Exact -> clearing.clearing_volumes.exact
    | Plus -> clearing.clearing_volumes.plus

  let get_cleared_sell_side_payout
    (from: token)
    (to: token)
    (amount: nat)
    (clearing: clearing)
    (tam: TokenAmountMap.t): TokenAmountMap.t =
    let f_sell_side_actual_volume: Rational.t = Rational.new (int clearing.prorata_equivalence.sell_side_actual_volume) in
    let f_amount = Rational.new (int amount) in
    let prorata_allocation = Rational.div f_amount f_sell_side_actual_volume in
    let f_buy_side_clearing_volume = Rational.new (int (get_clearing_volume clearing)) in
    let payout = Rational.mul prorata_allocation f_buy_side_clearing_volume in
    let payout_equiv = Rational.mul payout clearing.clearing_rate.rate in
    let remaining = Rational.sub f_amount payout_equiv in
    let fill_payout: token_amount = {
      token = to;
      amount = Utils.get_rounded_number_lower_bound payout;
    } in
    if Utils.gt remaining (Rational.new 1) then
      let token_rem : token_amount = {
         token = from;
         amount = Utils.get_rounded_number_lower_bound remaining;
      } in
      let u_tam = TokenAmountMap.increase fill_payout tam in
      TokenAmountMap.increase token_rem u_tam
    else
      TokenAmountMap.increase fill_payout tam

  let get_cleared_buy_side_payout
    (from: token)
    (to: token)
    (amount: nat)
    (clearing:clearing)
    (tam: Types.token_amount_map): Types.token_amount_map =
    let f_buy_side_actual_volume = Rational.new (int clearing.prorata_equivalence.buy_side_actual_volume) in
    let f_amount = Rational.new (int amount) in
    let prorata_allocation = Rational.div f_amount f_buy_side_actual_volume in
    let f_buy_side_clearing_volume = Rational.new (int (get_clearing_volume clearing)) in
    let f_sell_side_clearing_volume = Rational.mul clearing.clearing_rate.rate f_buy_side_clearing_volume in
    let payout = Rational.mul prorata_allocation f_sell_side_clearing_volume in
    let payout_equiv = Rational.div payout clearing.clearing_rate.rate in
    let remaining = Rational.sub f_amount payout_equiv in
    let fill_payout = {
      token = to;
      amount = Utils.get_rounded_number_lower_bound payout;
    } in
    if Utils.gt remaining (Rational.new 0) then
      let token_rem = {
         token = from;
         amount = Utils.get_rounded_number_lower_bound remaining;
      } in
      let u_tam = TokenAmountMap.increase fill_payout tam in
      TokenAmountMap.increase token_rem u_tam
    else
      TokenAmountMap.increase fill_payout tam

  let get_cleared_payout
    (ot: ordertype)
    (amt: nat)
    (clearing: clearing)
    (tam: Types.token_amount_map): Types.token_amount_map =
    let s = ot.side in
    let swap = clearing.clearing_rate.swap in
    match s with
    | Buy -> get_cleared_buy_side_payout swap.from.token swap.to amt clearing tam
    | Sell -> get_cleared_sell_side_payout swap.to swap.from.token amt clearing tam


  let collect_order_payout_from_clearing
    ((c, tam), (ot, amt): (clearing * Types.token_amount_map) * (ordertype * nat)) :  (clearing * Types.token_amount_map) =
    let u_tam: Types.token_amount_map  = if was_in_clearing ot c then
                                           get_cleared_payout ot amt c tam
                                         else
                                           let ta: token_amount = TokenAmount.recover ot amt c in
                                           TokenAmountMap.increase ta tam
    in
    (c, u_tam)

end

module Ubots = struct

type t = Types.user_batch_ordertypes
type order = Types.swap_order
type batch = Types.batch
type batch_set = Types.batch_set
type clearing = Types.clearing
type ordertypes = Types.ordertypes
type batch_ordertypes = Types.batch_ordertypes
type token_amount_map = Types.token_amount_map

let add_order
    (holder: address)
    (batch_id: nat)
    (order : order)
    (ubots: t ) : t =
    match Big_map.find_opt holder ubots with
    | None -> let new_bots = Batch_OrderTypes.make batch_id order in
              Big_map.add holder new_bots ubots
    | Some bots -> let updated_bots = Batch_OrderTypes.add_or_update batch_id order bots in
                   Big_map.update holder (Some updated_bots) ubots

let get_clearing
   (batch: batch) : clearing option =
   match batch.status with
   | Cleared ci -> Some ci.clearing
   | _ -> None


let collect_redemptions
    ((bots, tam, bts),(batch_number,otps) : (batch_ordertypes * token_amount_map * batch_set) * (nat * ordertypes)) : (batch_ordertypes * token_amount_map * batch_set) =
    let batches = bts.batches in
    let batch_indices = bts.current_batch_indices in
    match Big_map.find_opt batch_number batches with
    | None -> (bots, tam, bts)
    | Some batch -> (let name = Utils.get_rate_name_from_pair batch.pair in
                     match Map.find_opt name batch_indices with
                     | Some _ -> (bots, tam, bts)
                     | None ->
                       (match get_clearing batch with
                        | None ->  (bots, tam, bts)
                        | Some c -> let (_c, u_tam) = Map.fold Redemption_Utils.collect_order_payout_from_clearing otps (c, tam)  in
                                   let u_bots = Map.remove batch_number bots in
                                   (u_bots,u_tam, bts)))

let collect_redemption_payouts
    (holder: address)
    (batch_set: batch_set)
    (ubots: t) :  (t * token_amount_map) =
    let empty_tam = (Map.empty : token_amount_map) in
    match Big_map.find_opt holder ubots with
    | None -> (ubots, empty_tam)
    | Some bots -> let (u_bots, u_tam, _bs) = Map.fold collect_redemptions bots (bots, empty_tam, batch_set) in
                   let updated_ubots = Big_map.update holder (Some u_bots) ubots in
                   (updated_ubots, u_tam)


let is_within_limit
  (holder: address)
  (ubots: t) : bool =
  match Big_map.find_opt holder ubots with
  | None  -> true
  | Some bots -> let outstanding_token_items = Batch_OrderTypes.count bots in
                 outstanding_token_items <= Constants.limit_of_redeemable_items

end


module Treasury_Utils = struct

  type order = Types.swap_order
  type token_amount = Types.token_amount
  type token_amount_map = Types.token_amount_map
  type adjustment = INCREASE | DECREASE
  type order_list = order list


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

  let transfer_fa2_token
    (sender : address)
    (receiver : address)
    (token_address : address)
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
              token_id = 0n;
              amount = token_amount
            }
          ]
        }
      ] in
      Tezos.transaction transfer 0tez transfer_entrypoint


  (* Transfer the tokens to the appropriate address. This is based on the FA12 and FA2 token standard *)
  let transfer_token (sender : address) (receiver : address) (token_address : address) (token_amount : token_amount) : operation =
    match token_amount.token.standard with
    | Some standard ->
      if standard = Constants.fa12_token then
        transfer_fa12_token sender receiver token_address token_amount.amount
      else if standard = Constants.fa2_token then
        transfer_fa2_token sender receiver token_address token_amount.amount
      else
        failwith Errors.token_standard_not_found
    | None ->
        failwith Errors.token_standard_not_found


  let handle_transfer (sender : address) (receiver : address) (received_token : token_amount) : operation =
    match received_token.token.address with
    | None -> failwith Errors.xtz_not_currently_supported
    | Some token_address ->
        transfer_token sender receiver token_address received_token


 let transfer_holdings (treasury_vault : address) (holder: address)  (holdings : token_amount_map) : operation list =
    let atomic_transfer (operations, (_token_name,ta) : operation list * ( string * token_amount)) : operation list =
      let op: operation = handle_transfer treasury_vault holder ta in
      op :: operations
    in
    let op_list = Map.fold atomic_transfer holdings ([] : operation list)
    in
    op_list

 let transfer_fee (receiver : address) (amount : tez) : operation =
      match (Tezos.get_contract_opt receiver : unit contract option) with
      | None -> failwith Errors.invalid_tezos_address
      | Some rec_address -> Tezos.transaction () amount rec_address

end


module Treasury = struct

type order = Types.swap_order
type storage = Storage.t
type token_amount = Types.token_amount
type token_amount_map = Types.token_amount_map

let get_treasury_vault () : address = Tezos.get_self_address ()


let deposit
    (deposit_address : address)
    (deposited_token : token_amount)
    (fee_recipient: address)
    (fee_amount: tez) : operation list  =
      let treasury_vault = get_treasury_vault () in
      let fee_transfer_op = Treasury_Utils.transfer_fee fee_recipient fee_amount in
      let deposit_op = Treasury_Utils.handle_transfer deposit_address treasury_vault deposited_token in
      [ fee_transfer_op ; deposit_op]


let redeem
    (redeem_address : address)
    (storage : storage) : operation list * storage =
      let treasury_vault = get_treasury_vault () in
      let (updated_ubots, payout_token_map) = Ubots.collect_redemption_payouts redeem_address storage.batch_set storage.user_batch_ordertypes in
      let operations = Treasury_Utils.transfer_holdings treasury_vault redeem_address payout_token_map in
      let updated_storage = { storage with user_batch_ordertypes = updated_ubots; } in
      (operations, updated_storage)

end

module Token_Utils = struct

type token = Types.token
type side = Types.side
type swap = Types.swap
type valid_swaps = Storage.valid_swaps
type valid_tokens = Storage.valid_tokens

let are_equivalent_tokens
  (given: token)
  (test: token) : bool =
    given.name = test.name &&
    given.address = test.address &&
    given.decimals = test.decimals &&
    given.standard = test.standard

let is_valid_swap_pair
  (side: side)
  (swap: swap)
  (valid_swaps: valid_swaps): swap =
  let token_pair = Utils.pair_of_swap side swap in
  let rate_name = Utils.get_rate_name_from_pair token_pair in
  if Map.mem rate_name valid_swaps then swap else failwith Errors.unsupported_swap_type

let remove_token
  (token: token)
  (valid_tokens: valid_tokens) : valid_tokens =
  match Map.find_opt token.name valid_tokens with
  | Some existing_token -> if are_equivalent_tokens existing_token token then
                             Map.remove token.name valid_tokens
                           else
                             failwith Errors.token_already_exists_but_details_are_different
  | None -> valid_tokens


let add_token
  (token: token)
  (valid_tokens: valid_tokens) : valid_tokens =
  match Map.find_opt token.name valid_tokens with
  | Some existing_token -> if are_equivalent_tokens existing_token token then
                             valid_tokens
                           else
                             failwith Errors.token_already_exists_but_details_are_different
  | None -> Map.add token.name token valid_tokens

let is_token_used
  (token: token)
  (valid_swaps) : bool =
  let is_token_used_in_swap (acc, (_i, swap) : bool * (string * swap)) : bool =
    are_equivalent_tokens token swap.to ||
    are_equivalent_tokens token swap.from.token ||
    acc
  in
  Map.fold is_token_used_in_swap valid_swaps false

let add_swap
  (swap: swap)
  (valid_swaps: valid_swaps) : valid_swaps =
  let rate_name = Utils.get_rate_name_from_swap swap in
  Map.add rate_name swap valid_swaps

let remove_swap
  (swap: swap)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps) : (valid_swaps * valid_tokens) =
  let rate_name = Utils.get_rate_name_from_swap swap in
  let valid_swaps = Map.remove rate_name valid_swaps in
  let from = swap.from.token in
  let to = swap.to in
  let valid_tokens = if is_token_used from valid_swaps then
                       valid_tokens
                    else
                       remove_token from valid_tokens
  in
  let valid_tokens = if is_token_used to valid_swaps then
                       valid_tokens
                    else
                       remove_token to valid_tokens
  in
  (valid_swaps, valid_tokens)

end

module Tokens = struct

let validate
  (side: side)
  (swap: swap)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps): swap =
  let from = swap.from.token in
  let to = swap.to in
  match Map.find_opt from.name valid_tokens with
  | None ->  failwith Errors.unsupported_swap_type
  | Some ft -> (match Map.find_opt to.name valid_tokens with
                | None -> failwith Errors.unsupported_swap_type
                | Some tt -> if (Token_Utils.are_equivalent_tokens from ft) && (Token_Utils.are_equivalent_tokens to tt) then
                              Token_Utils.is_valid_swap_pair side swap valid_swaps
                            else
                              failwith Errors.unsupported_swap_type)

let remove_pair
  (swap: swap)
  (valid_swaps: valid_swaps)
  (valid_tokens: valid_tokens) : valid_swaps * valid_tokens =
  let from = swap.from.token in
  let to = swap.to in
  let rate_name = Utils.get_rate_name_from_swap swap in
  let inverse_rate_name = Utils.get_inverse_rate_name_from_pair (to,from) in
  let rate_found =  Map.find_opt rate_name valid_swaps in
  let inverted_rate_found = Map.find_opt inverse_rate_name valid_swaps in
  match (rate_found, inverted_rate_found) with
  | (Some _, _) -> Token_Utils.remove_swap swap valid_tokens valid_swaps
  | (None, Some _) -> failwith Errors.inverted_swap_already_exists
  | (None, None) ->  failwith Errors.swap_does_not_exist

let add_pair
  (swap: swap)
  (valid_swaps: valid_swaps)
  (valid_tokens: valid_tokens) : valid_swaps * valid_tokens =
  let from = swap.from.token in
  let to = swap.to in
  let rate_name = Utils.get_rate_name_from_swap swap in
  let inverse_rate_name = Utils.get_inverse_rate_name_from_pair (to,from) in
  let rate_found =  Map.find_opt rate_name valid_swaps in
  let inverted_rate_found = Map.find_opt inverse_rate_name valid_swaps in
  match (rate_found, inverted_rate_found) with
  | (Some _, _) -> failwith Errors.swap_already_exists
  | (None, Some _) -> failwith Errors.inverted_swap_already_exists
  | (None, None) -> let valid_tokens = Token_Utils.add_token from valid_tokens in
                    let valid_tokens = Token_Utils.add_token to valid_tokens in
                    let valid_swaps = Token_Utils.add_swap swap valid_swaps in
                    (valid_swaps, valid_tokens)

end

module Batch_Utils = struct

type batch_status =
  | Open of { start_time : timestamp }
  | Closed of { start_time : timestamp ; closing_time : timestamp }
  | Cleared of { at : timestamp; clearing : Types.clearing; rate : Types.exchange_rate }


let set_buy_side_volume
  (order: Types.swap_order)
  (volumes : Types.volumes) : Types.volumes =
  match order.tolerance with
  | Minus -> { volumes with buy_minus_volume = volumes.buy_minus_volume + order.swap.from.amount; }
  | Exact -> { volumes with buy_exact_volume = volumes.buy_exact_volume + order.swap.from.amount; }
  | Plus -> { volumes with buy_plus_volume = volumes.buy_plus_volume + order.swap.from.amount; }

let set_sell_side_volume
  (order: Types.swap_order)
  (volumes : Types.volumes) : Types.volumes =
  match order.tolerance with
  | Minus -> { volumes with sell_minus_volume = volumes.sell_minus_volume + order.swap.from.amount; }
  | Exact -> { volumes with sell_exact_volume = volumes.sell_exact_volume + order.swap.from.amount; }
  | Plus -> { volumes with sell_plus_volume = volumes.sell_plus_volume + order.swap.from.amount; }


let make
  (batch_number: nat)
  (timestamp: timestamp)
  (pair: Types.token * Types.token) : t =
  let volumes: Types.volumes = {
      buy_minus_volume = 0n;
      buy_exact_volume = 0n;
      buy_plus_volume = 0n;
      sell_minus_volume = 0n;
      sell_exact_volume = 0n;
      sell_plus_volume = 0n;
    } in
  {
    batch_number= batch_number;
    status = Open { start_time = timestamp } ;
    pair = pair;
    volumes = volumes;
  }

let update_current_batch_in_set
  (batch : t)
  (batch_set : batch_set) : (t * batch_set)=
  let updated_batches = Big_map.update batch.batch_number (Some batch) batch_set.batches in
  let name = Utils.get_rate_name_from_pair batch.pair in
  let updated_batch_indices = Map.update name (Some batch.batch_number) batch_set.current_batch_indices in
  ( batch, { batch_set with batches = updated_batches; current_batch_indices = updated_batch_indices; } )



let get_status_when_its_cleared (batch : t) =
  match batch.status with
    | Cleared infos -> infos
    | _ -> failwith Errors.batch_should_be_cleared

let should_be_cleared
  (batch : t)
  (current_time : timestamp) : bool =
  match batch.status with
    | Closed { start_time = _; closing_time } ->
      current_time > closing_time + Constants.price_wait_window
    | _ -> false

let start_period
  (pair : pair)
  (batch_set : batch_set)
  (current_time : timestamp) : (t * batch_set) =
  let highest_batch_index = Utils.get_highest_batch_index batch_set.current_batch_indices in
  let new_batch_number = highest_batch_index + 1n in
  let new_batch = make new_batch_number current_time pair in
  update_current_batch_in_set new_batch batch_set

let close (batch : t) : t =
  match batch.status with
    | Open { start_time } ->
      let batch_close_time = start_time + Constants.deposit_time_window in
      let new_status = Closed { start_time = start_time; closing_time = batch_close_time } in
      { batch with status = new_status }
    | _ -> failwith Errors.trying_to_close_batch_which_is_not_open


let new_batch_set : batch_set =
  {
    current_batch_indices = (Map.empty: (string, nat) map);
    batches= (Big_map.empty: (nat, t) big_map);
  }

let progress_batch
  (pair: pair)
  (batch: t)
  (batch_set: batch_set)
  (current_time : timestamp) : (t * batch_set) =
  match batch.status with
  | Open { start_time } ->
    if  current_time > start_time + Constants.price_wait_window then
      let closed_batch = close batch in
      update_current_batch_in_set closed_batch batch_set
    else
      (batch, batch_set)
  | Closed { closing_time =_ ; start_time = _} ->
    (*  Batches can only be cleared on receipt of rate so here they should just be returned *)
    (batch, batch_set)
  | Cleared _ -> start_period pair batch_set current_time

end

module Batch_Utils = struct

let update_volumes
  (order: Types.swap_order)
  (batch : t)  : t =
  let vols = batch.volumes in
  let updated_vols = match order.side with
                     | Buy -> BatchPriv.set_buy_side_volume order vols
                     | Sell -> BatchPriv.set_sell_side_volume order vols
  in
  { batch with volumes = updated_vols;  }

let can_deposit
  (batch:t) : bool =
  match batch.status with
  | Open _ -> true
  | _ -> false


let can_be_finalized
  (batch : t)
  (current_time : timestamp) : bool = BatchPriv.should_be_cleared batch current_time


let finalize_batch
  (batch : t)
  (clearing: clearing)
  (current_time : timestamp)
  (rate : Types.exchange_rate)
  (batch_set : batch_set): batch_set =
  let finalized_batch : t = {
      batch with status = Cleared {
        at = current_time;
        clearing = clearing;
        rate = rate
      }
    } in
  let (_, ucb) = BatchPriv.update_current_batch_in_set finalized_batch batch_set in
  ucb

let get_current_batch_without_opening
  (pair: pair)
  (current_time: timestamp)
  (batch_set: batch_set) : (t option * batch_set) =
  let current_batch_index = Utils.get_current_batch_index pair batch_set.current_batch_indices in
  match Big_map.find_opt current_batch_index batch_set.batches with
  | None ->  (None, batch_set)
  | Some cb ->  let (batch, batch_set) = BatchPriv.progress_batch pair cb batch_set current_time in
                (Some batch, batch_set)

let get_current_batch
  (pair: pair)
  (current_time: timestamp)
  (batch_set: batch_set) : (t * batch_set) =
  let current_batch_index = Utils.get_current_batch_index pair batch_set.current_batch_indices in
  match Big_map.find_opt current_batch_index batch_set.batches with
  | None ->  BatchPriv.start_period pair batch_set current_time
  | Some cb ->  BatchPriv.progress_batch pair cb batch_set current_time

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
  | Plus -> let val : Rational.t = exchange_rate.rate in
            let rate =  (Rational.mul val Constants.ten_bips_constant) in
            { exchange_rate with rate = rate}
  | Minus -> let val = exchange_rate.rate in
             let rate = (Rational.div val Constants.ten_bips_constant) in
             { exchange_rate with rate = rate}

[@inline]
let filter_volumes
  (volumes: volumes)
  (clearing: clearing) : (nat * nat) =
  match clearing.clearing_tolerance with
  | Minus -> let buy_vol = volumes.buy_minus_volume + volumes.buy_exact_volume + volumes.buy_plus_volume in
             (buy_vol, volumes.sell_minus_volume)
  | Exact -> let buy_vol = volumes.buy_exact_volume + volumes.buy_plus_volume in
             let sell_vol = volumes.sell_minus_volume + volumes.sell_exact_volume in
             (buy_vol, sell_vol)
  | Plus -> let sell_vol = volumes.sell_minus_volume + volumes.sell_exact_volume + volumes.sell_plus_volume in
            (volumes.buy_plus_volume, sell_vol)

[@inline]
let compute_equivalent_amount (amount : nat) (rate : exchange_rate) (invert: bool) : nat =
  let float_amount = Rational.new (int (amount)) in
  if invert then
    Utils.get_rounded_number_lower_bound (Rational.div float_amount rate.rate)
  else
    Utils.get_rounded_number_lower_bound (Rational.mul float_amount rate.rate)

(*
  This function builds the order equivalence for the pro-rata redeemption.
*)
let build_equivalence
  (volumes: volumes)
  (clearing : clearing)
  (rate : exchange_rate) : clearing =
  let clearing_rate = get_clearing_rate clearing rate in
  let (bid_amounts, ask_amounts) = filter_volumes volumes clearing in
  let bid_equivalent_amounts = compute_equivalent_amount bid_amounts clearing_rate false in
  let ask_equivalent_amounts = compute_equivalent_amount ask_amounts clearing_rate true in
  let equivalence = {
    buy_side_actual_volume = bid_amounts;
    buy_side_actual_volume_equivalence = bid_equivalent_amounts;
    sell_side_actual_volume = ask_amounts;
    sell_side_actual_volume_equivalence = ask_equivalent_amounts;
  } in
  { clearing with prorata_equivalence = equivalence; clearing_rate = clearing_rate }


let compute_clearing_prices
  (rate: CommonTypes.Types.exchange_rate)
  (current_batch : Batch.t) : clearing =
  let volumes = current_batch.volumes in
  let sell_cp_minus = int (volumes.sell_minus_volume) in
  let sell_cp_exact = int (volumes.sell_exact_volume) in
  let sell_cp_plus = int (volumes.sell_plus_volume) in

  let buy_cp_minus = int (volumes.buy_minus_volume) in
  let buy_cp_exact = int (volumes.buy_exact_volume) in
  let buy_cp_plus = int (volumes.buy_plus_volume) in


  let buy_side : buy_side = (buy_cp_minus, buy_cp_exact, buy_cp_plus) in
  let sell_side : sell_side = (sell_cp_minus, sell_cp_exact, sell_cp_plus) in

  let clearing = Utils.get_clearing_price rate buy_side sell_side in
  let with_equiv = build_equivalence volumes clearing rate in
  with_equiv

end

type storage  = Storage.t
type result = (operation list) * storage
type order = Types.swap_order
type swap = Types.swap
type valid_swaps = Storage.valid_swaps
type valid_tokens = Storage.valid_tokens
type external_order = Types.external_swap_order
type side = Types.side
type tolerance = Types.tolerance
type rate = Types.exchange_rate
type inverse_rate = rate
type batch_set = Types.batch_set
type batch = Types.batch
type clearing = Types.clearing
type pair = Types.pair
type token = Types.token
let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
  | Deposit of external_order
  | Post of rate
  | Redeem
  | ChangeFee of tez
  | ChangeAdminAddress of address
  | Add_token_swap_pair of swap
  | Remove_token_swap_pair of swap

let is_administrator
  (storage : storage) : unit =
  assert_with_error
   (Tezos.get_sender () = storage.administrator)
   (failwith Errors.sender_not_administrator)

let invert_rate_for_clearing
  (rate : rate) : rate  =
  let base_token = rate.swap.from.token in
  let quote_token = rate.swap.to in
  let new_base_token = { rate.swap.from with token = quote_token } in
  let new_quote_token = base_token in
  let new_rate: rate = {
      swap = { from = new_base_token; to = new_quote_token };
      rate = Rational.inverse rate.rate;
      when = rate.when;
  } in
  new_rate

let finalize
  (batch : batch)
  (current_time : timestamp)
  (rate : rate)
  (batch_set : batch_set): batch_set =
  if Batch.can_be_finalized batch current_time then
    let current_time = Tezos.get_now () in
    let inverse_rate : rate = invert_rate_for_clearing rate in
    let clearing : clearing = Clearing.compute_clearing_prices inverse_rate batch in
    Batch.finalize_batch batch clearing current_time rate batch_set
  else
    batch_set

let external_to_order
  (order: external_order)
  (order_number: nat)
  (batch_number: nat)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps): order =
  let side = Utils.nat_to_side(order.side) in
  let tolerance = Utils.nat_to_tolerance(order.tolerance) in
  let sender = Tezos.get_sender () in
  let converted_order : order =
    {
      order_number = order_number;
      batch_number = batch_number;
      trader = sender;
      swap  = order.swap;
      created_at = order.created_at;
      side = side;
      tolerance = tolerance;
      redeemed = false;
    } in
  let validated_swap = Tokens.validate side order.swap valid_tokens valid_swaps in
  { converted_order with swap = validated_swap; }

(* Register a deposit during a valid (Open) deposit time; fails otherwise.
   Updates the current_batch if the time is valid but the new batch was not initialized. *)
let deposit (external_order: external_order) (storage : storage) : result =
  let pair = Utils.pair_of_external_swap external_order in
  let current_time = Tezos.get_now () in

  let fee_amount_in_mutez = storage.fee_in_mutez in
  let fee_provided = Tezos.get_amount () in
  if fee_provided < fee_amount_in_mutez then failwith Errors.insufficient_swap_fee else

  let (current_batch, current_batch_set) = Batch.get_current_batch pair current_time storage.batch_set in
  let storage = { storage with batch_set = current_batch_set } in
  if Batch.can_deposit current_batch then
     let current_batch_number = current_batch.batch_number in
     let next_order_number = storage.last_order_number + 1n in
     let order : order = external_to_order external_order next_order_number current_batch_number storage.valid_tokens storage.valid_swaps in
     (* We intentionally limit the amount of distinct orders that can be placed whilst unredeemed orders exist for a given user  *)
     if Ubot.is_within_limit order.trader storage.user_batch_ordertypes then
       let new_ubot = Ubot.add_order order.trader current_batch_number order storage.user_batch_ordertypes in
       let updated_volumes = Batch.update_volumes order current_batch in
       let updated_batches = Big_map.update current_batch_number (Some updated_volumes) current_batch_set.batches in
       let updated_batch_set = { current_batch_set with batches = updated_batches } in
       let updated_storage = {
         storage with batch_set = updated_batch_set;
         last_order_number = next_order_number;
         user_batch_ordertypes = new_ubot; } in
       let fee_recipient = storage.fee_recipient in
       let treasury_ops = Treasury.deposit order.trader order.swap.from fee_recipient fee_amount_in_mutez in
       (treasury_ops, updated_storage)

      else
        failwith Errors.too_many_unredeemed_orders
  else
    failwith Errors.no_open_batch_for_deposits

let redeem
 (storage : storage) : result =
  let holder = Tezos.get_sender () in
  let (tokens_transfer_ops, new_storage) = Treasury.redeem holder storage in
  (tokens_transfer_ops, new_storage)

(* Post the rate in the contract and check if the current batch of orders needs to be cleared. *)
let post_rate (rate : rate) (storage : storage) : result =
  let validated_swap = Tokens.validate Buy rate.swap storage.valid_tokens storage.valid_swaps in
  let rate  = { rate with swap = validated_swap; } in
  let storage = Pricing.Rates.post_rate rate storage in
  let pair = Utils.pair_of_rate rate in
  let current_time = Tezos.get_now () in
  let batch_set = storage.batch_set in
  let (batch_opt, batch_set) = Batch.get_current_batch_without_opening pair current_time batch_set in
  match batch_opt with
  | Some b -> let batch_set = finalize b current_time rate batch_set in
              let storage = { storage with batch_set = batch_set } in
              no_op (storage)
  | None ->   no_op (storage)


let change_fee
    (new_fee: tez)
    (storage: storage) : result =
    let () = is_administrator storage in
    let storage = { storage with fee_in_mutez = new_fee; } in
    no_op (storage)

let change_admin_address
    (new_admin_address: address)
    (storage: storage) : result =
    let _ = is_administrator storage in
    let storage = { storage with administrator = new_admin_address; } in
    no_op (storage)


let add_token_swap_pair
  (swap: swap)
  (storage: storage) : result =
   let () = is_administrator storage in
   let (u_swaps,u_tokens) = Tokens.add_pair swap storage.valid_swaps storage.valid_tokens in
   let storage = { storage with valid_swaps = u_swaps; valid_tokens = u_tokens; } in
   no_op (storage)

let remove_token_swap_pair
  (swap: swap)
  (storage: storage) : result =
   let () = is_administrator storage in
   let (u_swaps,u_tokens) = Tokens.remove_pair swap storage.valid_swaps storage.valid_tokens in
   let storage = { storage with valid_swaps = u_swaps; valid_tokens = u_tokens; } in
   no_op (storage)

let main
  (action, storage : entrypoint * storage) : result =
  match action with
   | Deposit order -> deposit order storage
   | Post new_rate -> post_rate new_rate storage
   | Redeem -> redeem storage
   | ChangeFee new_fee -> change_fee new_fee storage
   | ChangeAdminAddress new_admin_address -> change_admin_address new_admin_address storage
   | Add_token_swap_pair swap -> add_token_swap_pair swap storage
   | Remove_token_swap_pair token -> remove_token_swap_pair token storage



