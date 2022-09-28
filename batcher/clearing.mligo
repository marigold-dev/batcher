#import "constants.mligo" "Constants"
#import "types.mligo" "CommonTypes"
#import "storage.mligo" "CommonStorage"
#import "prices.mligo" "Pricing"
#import "math.mligo" "Math"
#import "orderbook.mligo" "Order"
#import "../math_lib/lib/float.mligo" "Float"

type storage  = CommonStorage.Types.t
type side  = CommonTypes.Types.side
type tolerance = CommonTypes.Types.tolerance
type clearing = CommonTypes.Types.clearing
type exchange_rate= CommonTypes.Types.exchange_rate
type order = CommonTypes.Types.swap_order

type orderbook = Order.t

type orders = order list
type buy_side = CommonTypes.Types.buy_side
type sell_side = CommonTypes.Types.sell_side

[@inline]
let get_distribution_of
  (side, tolerance : side * tolerance) (orderbook : orderbook) : nat
=
  let side_orders = 
      match side with
      | BUY -> orderbook.bids
      | SELL -> orderbook.asks
  in
  let collect (acc, o : nat * order) : nat =
    match (tolerance, o.tolerance) with 
    | (MINUS, MINUS) -> acc + o.swap.from.amount 
    | (EXACT, EXACT) -> acc + o.swap.from.amount 
    | (PLUS, PLUS) -> acc + o.swap.from.amount 
    | _ -> acc
  in 
  List.fold collect side_orders 0n

let compute_clearing_prices
  (rate: CommonTypes.Types.exchange_rate)
  (storage : storage) : clearing
=
  let current_batch =
    match storage.batches.current with
      | None -> failwith "No current batch"
      | Some batch -> batch
  in
  let orderbook = current_batch.orderbook in


  let sell_cp_minus = int (get_distribution_of (SELL,MINUS) orderbook) in
  let sell_cp_exact = int (get_distribution_of (SELL,EXACT) orderbook) in
  let sell_cp_plus = int (get_distribution_of (SELL,PLUS) orderbook) in

  let buy_cp_minus = int (get_distribution_of (BUY,MINUS) orderbook) in
  let buy_cp_exact = int (get_distribution_of (BUY,EXACT) orderbook) in
  let buy_cp_plus = int (get_distribution_of (BUY,PLUS) orderbook) in


  let buy_side : buy_side = (buy_cp_minus, buy_cp_exact, buy_cp_plus) in 
  let sell_side : sell_side = (sell_cp_minus, sell_cp_exact, sell_cp_plus) in

  let clearing = Math.get_clearing_price rate.rate buy_side sell_side in
  clearing
