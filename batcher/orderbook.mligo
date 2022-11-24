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
  let aux (ord_acc, order : order list * order) : order list =
    if f order then order :: ord_acc
    else
      ord_acc
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
  filter the oderbook based on the clearing
*)
let filter
  (orderbook : t)
  (clearing : clearing) :  t =
  let filtered_orderbook =
    trigger_filtering_orders orderbook clearing in
  let bids = filtered_orderbook.bids in
  let asks = filtered_orderbook.asks in
  {orderbook with bids = bids; asks = asks}

(*
  get the equivalence object based on the filtered orderbook
*)
let get_equivalence
  (orderbook : t)
  (clearing : clearing)
  (exchange_rate : CommonTypes.Types.exchange_rate) : clearing =
  let filtered_orderbook = filter orderbook clearing in
  build_equivalence filtered_orderbook.bids filtered_orderbook.asks clearing exchange_rate



