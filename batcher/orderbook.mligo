#import "types.mligo" "CommonTypes"
#import "utils.mligo" "Utils"

type order = CommonTypes.Types.swap_order
type side = CommonTypes.Types.side
type tolerance = CommonTypes.Types.tolerance
type clearing = CommonTypes.Types.clearing

(*This type represent a result of a match computation, 
  we can partially or totally match two order, and if the volume of token we can use is
  equal to 0 there is no match*)
type matching = No_match | Total | Partial of order

type key = side

(*
  A bid : the price a buyer is willing to pay for an asset
  A ask : the price a seller is willing to accept for an asset

  Here, the orderbook is a list of bids orders and asks orders
*)
type t = {
  bids : order list;
  asks : order list
}

let empty () : t = {bids = ([] : order list); asks = ([] : order list)}

let make_new_order (order : order) (amt: nat) : order =
  let new_token_amount = 
    {order.swap.from with amount = amt} in
  let new_swap = {order.swap with from = new_token_amount} in
  {order with swap = new_swap}

let match_orders (ord_1 : order) (_ord_2 : order) : matching =
    (*let ord1_new_amount = ord1.from_amount - ord2.from_amount in
    let ord2_new_amount = ord2.from_amount - ord1.from_amount in
    if ord1_new_amount = 0 && ord2_new_amount = 0 then
      Total
    else
    if ord1_new_amount > 0 then Partial { ord1 with from_amount = (abs ord2_new_amount) }
    else
      Partial { ord2 with from_amount = (abs ord2_new_amount) }*)
    Partial (make_new_order ord_1 50n)

(*This function push orders according to a pro-rata "model"*)
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
let filter_orders (orders: order list) (f : order -> bool) : order list =
  let aux (new_odb, order : order list * order) : order list =
    if f order then order :: new_odb
    else
     (* call redeem for this order *)
      new_odb
  in
  List.fold_left aux ([] : order list) orders

let trigger_filtering_orders (orderbook : t) (clearing : clearing) : t =
  let (f_bids,f_asks) =
    match clearing.clearing_tolerance with
     | MINUS ->
       ((fun (_: order) -> true), (fun (order : order) -> order.tolerance = MINUS))
     | EXACT ->
       ((fun (order : order) -> order.tolerance = EXACT || order.tolerance = PLUS),
        (fun (order : order) -> order.tolerance = MINUS || order.tolerance = EXACT))
     | PLUS ->
       ((fun (order : order) -> order.tolerance = PLUS), (fun (_:order) -> true))
  in
  let new_bids = filter_orders orderbook.bids f_bids in
  let new_asks = filter_orders orderbook.asks f_asks in

  {orderbook with bids = new_bids; asks = new_asks}

let orders_execution (orderbook : t) (clearing : clearing) : t =
  let filtered_orderbook = 
    trigger_filtering_orders orderbook clearing in
  filtered_orderbook
  (* un-queue bids/asks orders and call match orders *)
  
  