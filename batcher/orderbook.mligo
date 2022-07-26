#import "types.mligo" "CommonTypes"
#import "utils.mligo" "Utils"
#import "errors.mligo" "Errors"
#import "types.mligo" "CommonTypes"
#import "math.mligo" "Math"
#import "../math_lib/lib/float.mligo" "Float"
#import "treasury.mligo" "Treasury"
#import "constants.mligo" "Constants"

type order = CommonTypes.Types.swap_order
type side = CommonTypes.Types.side
type tolerance = CommonTypes.Types.tolerance
type clearing = CommonTypes.Types.clearing
type exchange_rate = CommonTypes.Types.exchange_rate
type t = CommonTypes.Types.orderbook

(*This type represent a result of a match computation,
  we can partially or totally match two order, and if the volume of token we can use is
  equal to 0 there is no match*)
type matching = Total | Partial of order

type key = side

type match_calculation_type = EXACT_MATCH | LEFT_PARTIAL | RIGHT_PARTIAL

let empty () : t = Map.literal [("bids", ([] : order list)); "asks", ([] : order list)]

let get_side_or_empty
  (side: string)
  (orderbook : t) : order list =
  match Map.find_opt side orderbook with
  | None -> ([]: order list)
  | Some ol -> ol

let update_order_sides
  (bids: order list)
  (asks: order list)
  (orderbook : t) : t =
  let updated_bids : t  = Map.update "bids" (Some(bids)) orderbook in
  let updated : t = Map.update "asks" (Some(asks)) updated_bids in
  (updated : t)

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
(*This function push orders to the order book*)
let push_order (order : order) (orderbook : t) : t =
  let side = match order.side with
      | BUY ->  "bids"
      | SELL -> "asks"
  in
  match Map.find_opt side orderbook with
  | None -> (failwith Errors.unable_to_find_side_in_orderbook : t)
  | Some(ol) -> Map.update side (Some(order :: ol )) orderbook

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
  let orig_bids = get_side_or_empty "bids" orderbook in
  let orig_asks = get_side_or_empty "asks" orderbook in
  let new_bids = filter_orders orig_bids f_bids in
  let new_asks = filter_orders orig_asks f_asks in
  update_order_sides new_bids new_asks orderbook

let sum_order_amounts
  (orders : order list): nat =
  let amounts : nat list = List.map (fun (o:order) -> o.swap.from.amount) (orders) in
  let sum (acc, i : nat * nat) : nat = acc + i in
  List.fold sum amounts 0n


(*
 Get the correct exchange rate based on the clearing price
*)
let get_clearing_rate
  (clearing: clearing)
  (exchange_rate: exchange_rate) : exchange_rate =
  match clearing.clearing_tolerance with
  | EXACT -> exchange_rate
  | PLUS -> let val : Float.t = exchange_rate.rate in
            let rate =  (Float.mul val Constants.ten_bips_constant) in
            { exchange_rate with rate = rate}
  | MINUS -> let val = exchange_rate.rate in
             let rate = (Float.div val Constants.ten_bips_constant) in
             { exchange_rate with rate = rate}


(*
  This function builds the order equivalence for the pro-rata redeemption.
*)
let build_equivalence
  (bids: order list)
  (asks: order list)
  (clearing : clearing)
  (exchange_rate : CommonTypes.Types.exchange_rate) : clearing =
  let clearing_rate = get_clearing_rate clearing exchange_rate in
  let bid_amounts = sum_order_amounts bids in
  let ask_amounts = sum_order_amounts asks in
  let bid_equivalent_amounts = compute_equivalent_amount bid_amounts clearing_rate false in
  let ask_equivalent_amounts = compute_equivalent_amount ask_amounts clearing_rate true in
  let equivalence = {
    buy_side_actual_volume = bid_amounts;
    buy_side_actual_volume_equivalence = bid_equivalent_amounts;
    sell_side_actual_volume = ask_amounts;
    sell_side_actual_volume_equivalence = ask_equivalent_amounts;
  } in
  { clearing with prorata_equivalence = equivalence; clearing_rate = clearing_rate }

(*
  get the equivalence object based on the filtered orderbook
*)
let get_equivalence
  (orderbook : t)
  (clearing : clearing)
  (exchange_rate : CommonTypes.Types.exchange_rate) : clearing =
  let filtered_orderbook = trigger_filtering_orders orderbook clearing in
  let filtered_bids = get_side_or_empty "bids" filtered_orderbook in
  let filtered_asks = get_side_or_empty "asks" filtered_orderbook in
  build_equivalence filtered_bids filtered_asks clearing exchange_rate



