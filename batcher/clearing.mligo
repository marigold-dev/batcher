#import "constants.mligo" "Constants"
#import "types.mligo" "CommonTypes"
#import "storage.mligo" "CommonStorage"
#import "prices.mligo" "Pricing"
#import "math.mligo" "Math"

type storage  = CommonStorage.Types.t
type side  = CommonTypes.Types.side
type tolerance = CommonTypes.Types.tolerance
type clearing = CommonTypes.Types.clearing
type exchange_rate= CommonTypes.Types.exchange_rate
type order = CommonTypes.Types.swap_order
type orders = order list
type buy_side = CommonType.Types.buy_side
type sell_side = CommonType.Types.sell_side

let get_distribution_of
  (side, tolerance : side * tolerance) (orders : orders) : nat
=
  let collect(acc, o : nat * order) : nat  =  (if (side, tolerance) = (o.side, o.tolerance) then (acc + o.swap.from.amount) else acc)  in
  List.fold collect orders 0n


let compute_clearing_prices
  (rate: CommonTypes.Types.exchange_rate)
  (storage : storage) : clearing
=
  let current_batch =
    match storage.batches.current with
      | None -> failwith "No current batch"
      | Some batch -> batch
  in
  let exchange_rate = Pricing.Rates.get_rate rate.swap storage in
  let orders = current_batch.orders in

  let sell_cp_minus = int (get_distribution_of (SELL,MINUS) orders) in
  let sell_cp_exact = int (get_distribution_of (SELL,EXACT) orders) in
  let sell_cp_plus = int (get_distribution_of (SELL,PLUS) orders) in

  let buy_cp_minus = int (get_distribution_of (BUY,MINUS) orders) in
  let buy_cp_exact = int (get_distribution_of (BUY,EXACT) orders) in
  let buy_cp_plus = int (get_distribution_of (BUY,PLUS) orders) in

  let buy_side : buy_side = (buy_cp_minus, buy_cp_exact, buy_cp_plus) in 
  let sell_side : sell_side = (sell_cp_minus, sell_cp_exact, sell_cp_plus) in

  let clearing = Math.get_clearing_price exchange_rate.rate buy_side sell_side in
  clearing
