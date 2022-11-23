#import "types.mligo" "CommonTypes"
#import "utils.mligo" "Utils"
#import "types.mligo" "CommonTypes"
#import "math.mligo" "Math"
#import "../math_lib/lib/float.mligo" "Float"
#import "treasury.mligo" "Treasury"

type order = CommonTypes.Types.swap_order
type side = CommonTypes.Types.side
type tolerance = CommonTypes.Types.tolerance
type clearing = CommonTypes.Types.clearing
type treasury = CommonTypes.Types.treasury
type exchange_rate = CommonTypes.Types.exchange_rate
type t = CommonTypes.Types.orderbook

(*This type represent a result of a match computation,
  we can partially or totally match two order, and if the volume of token we can use is
  equal to 0 there is no match*)
type matching = Total | Partial of order

type key = side

type match_calculation_type = EXACT_MATCH | LEFT_PARTIAL | RIGHT_PARTIAL

let empty () : t = {bids = ([] : order list); asks = ([] : order list)}

[@inline]
let compute_equivalent_amount (amount : nat) (exchange_rate : exchange_rate) (invert: bool) : nat =
  let float_amount = Float.new (int (amount)) 0 in
  if invert then
    Math.get_rounded_number (Float.div float_amount exchange_rate.rate)
  else
    Math.get_rounded_number (Float.mul float_amount exchange_rate.rate)

[@inline]
let compute_equivalent_token (order : order) (exchange_rate : exchange_rate) : nat =
  let float_amount = Float.new (int (order.swap.from.amount)) 0 in
  if order.swap.from.token = exchange_rate.swap.from.token then
    Math.get_rounded_number (Float.mul float_amount exchange_rate.rate)
  else
    Math.get_rounded_number (Float.div float_amount exchange_rate.rate)

[@inline]
let make_new_order (order : order) (amt: nat) : order =
  let new_token_amount =
    {order.swap.from with amount = amt} in
  let new_swap = {order.swap with from = new_token_amount} in
  {order with swap = new_swap}

[@inline]
let get_match_type (equivalent_ord_1_amount : nat) (ord_2 : order)  : match_calculation_type =
    if (ord_2.swap.from.amount > equivalent_ord_1_amount) then RIGHT_PARTIAL else
      if (ord_2.swap.from.amount < equivalent_ord_1_amount) then
        LEFT_PARTIAL
      else
        EXACT_MATCH

(*
  For a right partial match we need to find the correct amount of ord_2 to swap that is equivalent
  to the amount in ord_1 and pass that to the treasury to be swapped.  In addition, we need to understand
  the remaining amount from order 2 that will be be left in the order book to be matched in the next
  iteration of matching
*)
let right_partial_match
  (equivalent_ord_1_amount : nat)
  (ord_1 : order)
  (ord_2 : order)
  (treasury : CommonTypes.Types.treasury) : treasury * matching * matching =
    (* Here we get the amount that is remaining after the swap is done that will remain to be matched to another swap *)
    let ord_2_remaining_token = ord_2.swap.from.amount - equivalent_ord_1_amount in
    (*  We need to create a new token amount that can be swapped for the partial amount *)
    let new_token_amount_2 = { ord_2.swap.from with amount = equivalent_ord_1_amount } in
    let token_holding_1 = CommonTypes.Utils.token_amount_to_token_holding ord_1.trader ord_1.swap.from false in
    let token_holding_2 = CommonTypes.Utils.token_amount_to_token_holding ord_2.trader new_token_amount_2 false in
    let updated_treasury = Treasury.swap (token_holding_1) (token_holding_2) treasury in
    updated_treasury, Total, Partial (make_new_order ord_2 (abs ord_2_remaining_token) )


(*
  For a left partial match we need to find the correct amount of ord_1 to swap that is equivalent
  to the amount in ord_2 and pass that to the treasury to be swapped.  In addition, we need to understand
  the remaining amount from order 1 that will be be left in the order book to be matched in the next
  iteration of matching
*)
let left_partial_match
  (equivalent_ord_2_amount : nat)
  (ord_1 : order)
  (ord_2 : order)
  (treasury : CommonTypes.Types.treasury) : treasury * matching * matching =
    let ord_1_remaining_token = ord_1.swap.from.amount - equivalent_ord_2_amount in
    let new_token_amount_1 = { ord_1.swap.from with amount = equivalent_ord_2_amount } in
    let token_holding_1 = CommonTypes.Utils.token_amount_to_token_holding ord_1.trader new_token_amount_1 false in
    let token_holding_2 = CommonTypes.Utils.token_amount_to_token_holding ord_2.trader ord_2.swap.from false in
    let updated_treasury = Treasury.swap (token_holding_1) (token_holding_2) treasury in
    updated_treasury, Partial (make_new_order ord_1 (abs ord_1_remaining_token)), Total

let total_match
  (_equivalent_ord_1_amount : nat)
  (ord_1 : order)
  (ord_2 : order)
  (treasury : CommonTypes.Types.treasury) : treasury * matching * matching =
    let token_holding_1 = CommonTypes.Utils.token_amount_to_token_holding ord_1.trader ord_1.swap.from false in
    let token_holding_2 = CommonTypes.Utils.token_amount_to_token_holding ord_2.trader ord_2.swap.from false in
    let updated_treasury = Treasury.swap (token_holding_1) (token_holding_2) treasury in
    updated_treasury, Total, Total



(*
  Here we actually match order, and call transfer function when necessary
  it is mandatory that one of the two orders will be totally executed,
  and the other one, partially.
*)
let match_orders
  (ord_1 : order)
  (ord_2 : order)
  (exchange_rate : CommonTypes.Types.exchange_rate)
  (treasury : CommonTypes.Types.treasury) : treasury * matching * matching =
  let equivalent_ord_1_amount : nat = compute_equivalent_token ord_1 exchange_rate in
  let match_calculation =
    match get_match_type equivalent_ord_1_amount ord_2 with
    | RIGHT_PARTIAL ->  right_partial_match equivalent_ord_1_amount ord_1 ord_2 treasury
    | LEFT_PARTIAL ->
      let equivalent_ord_2_amount : nat = compute_equivalent_token ord_2 exchange_rate in
      left_partial_match equivalent_ord_2_amount ord_1 ord_2 treasury
    | EXACT_MATCH ->
      total_match equivalent_ord_1_amount ord_1 ord_2 treasury
  in
  match_calculation


[@inline]
(*This function push orders auxording to a pro-rata "model"*)
let push_order (order : order) (orderbook : t) : t =
  match order.side with
    | BUY ->  {orderbook with bids = (order :: orderbook.bids)}
    | SELL -> {orderbook with asks = (order :: orderbook.asks)}

(*
   This function should be call only once during a batch period,
   actually once for bids, once for asks, during a batch period.
   when we compute the clearing level and want to trigger the orders_execution.
   in fact, when we push order in the orderbook, we have to inverse
   the lists to get the right queues with whom we can trigger
   the orders_execution. Thats why i use Fold.left instead of
   putting List.rev everywhere like the previous design.
*)
[@inline]
let filter_orders (orders: order list) (f : order -> bool) : order list =
  let aux (new_odb, order : order list * order) : order list =
    if f order then order :: new_odb
    else
     (* call redeem for this order *)
      new_odb
  in
  List.fold_left aux ([] : order list) orders

[@inline]
let trigger_filtering_orders (orderbook : t) (clearing : clearing) : t =
  let (f_bids,f_asks) =
    match clearing.clearing_tolerance with
     | MINUS ->
       ((fun (_: order) -> true),
       (fun (order : order) -> order.tolerance = MINUS))
     | EXACT ->
       ((fun (order : order) ->
         order.tolerance = EXACT || order.tolerance = PLUS),
        (fun (order : order) ->
         order.tolerance = MINUS || order.tolerance = EXACT))
     | PLUS ->
       ((fun (order : order) -> order.tolerance = PLUS),
       (fun (_:order) -> true))
  in
  let new_bids = filter_orders orderbook.bids f_bids in
  let new_asks = filter_orders orderbook.asks f_asks in
  {orderbook with bids = new_bids; asks = new_asks}

let sum_order_amounts
  (orders : order list): nat =
  let amounts : nat list = List.map (fun (o:order) -> o.swap.from.amount) (orders) in
  let sum (acc, i : nat * nat) : nat = acc + i in
  List.fold sum amounts 0n

(*
  This function builds the order equivalence for the pro-rata redeemption.
*)
let build_equivalence
  (bids: order list)
  (asks: order list)
  (clearing : clearing)
  (exchange_rate : CommonTypes.Types.exchange_rate) : clearing =
  let bid_amounts = sum_order_amounts bids in
  let ask_amounts = sum_order_amounts asks in
  let bid_equivalent_amounts = compute_equivalent_amount bid_amounts exchange_rate false in
  let ask_equivalent_amounts = compute_equivalent_amount ask_amounts exchange_rate true in
  let equivalence = {
    buy_side_actual_volume = bid_amounts;
    buy_side_actual_volume_equivalence = bid_equivalent_amounts;
    sell_side_actual_volume = ask_amounts;
    sell_side_actual_volume_equivalence = ask_equivalent_amounts;
  } in
  { clearing with prorata_equivalence= equivalence }

(*
  rem = remaining
*)
let orders_execution
  (orderbook : t)
  (clearing : clearing)
  (exchange_rate : CommonTypes.Types.exchange_rate)
  (treasury : CommonTypes.Types.treasury ): treasury * t =
  let rec aux
    (t, bids, asks, rem_bids, rem_asks :
     treasury * order list * order list * order list * order list)
    : treasury * order list * order list
  =
  match t, bids, asks with
   | tr, [],[] -> tr, rem_bids,rem_asks
   | tr, bid::bids, [] ->
     aux (tr, bids,([] : order list),(bid::rem_bids),rem_asks)
   | tr, [], ask::asks ->
     aux (tr, ([] : order list),asks,rem_bids,(ask::rem_asks))
   | tr, bid::bids, ask::asks ->
     (match (match_orders bid ask exchange_rate tr) with
      | nt, Total, Partial new_ask ->
        aux (nt,bids,(new_ask::asks),rem_bids,rem_asks)
      | nt, Partial new_bid, Total ->
        aux (nt, (new_bid::bids),asks,rem_bids,rem_asks)
      | nt, _, _ -> aux (nt,bids,asks,rem_bids,rem_asks))
  in
  let filtered_orderbook =
    trigger_filtering_orders orderbook clearing in
  let bids = filtered_orderbook.bids in
  let asks = filtered_orderbook.asks in
  let (ft, rem_bids, rem_asks) =
    aux (treasury, bids, asks, ([] : order list ),([] : order list)) in
  ft, {orderbook with bids = rem_bids; asks = rem_asks}
