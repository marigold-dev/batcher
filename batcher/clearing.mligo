#import "constants.mligo" "Constants"
#import "batch.mligo" "Batch"
#import "types.mligo" "CommonTypes"
#import "storage.mligo" "CommonStorage"
#import "prices.mligo" "Pricing"
#import "math.mligo" "Math"
#import "orderbook.mligo" "Order"
#import "../math_lib/lib/rational.mligo" "Rational"

type storage  = CommonStorage.Types.t
type side  = CommonTypes.Types.side
type tolerance = CommonTypes.Types.tolerance
type clearing = CommonTypes.Types.clearing
type exchange_rate = CommonTypes.Types.exchange_rate
type order = CommonTypes.Types.swap_order
type volumes = CommonTypes.Types.volumes

type orderbook = Order.t

type orders = order list
type buy_side = CommonTypes.Types.buy_side
type sell_side = CommonTypes.Types.sell_side


(*
 Get the correct exchange rate based on the clearing price
*)
[@inline]
let get_clearing_rate
  (clearing: clearing)
  (exchange_rate: exchange_rate) : exchange_rate =
  match clearing.clearing_tolerance with
  | EXACT -> exchange_rate
  | PLUS -> let val : Rational.t = exchange_rate.rate in
            let rate =  (Rational.mul val Constants.ten_bips_constant) in
            { exchange_rate with rate = rate}
  | MINUS -> let val = exchange_rate.rate in
             let rate = (Rational.div val Constants.ten_bips_constant) in
             { exchange_rate with rate = rate}

[@inline]
let filter_volumes
  (volumes: volumes)
  (clearing: clearing) : (nat * nat) =
  match clearing.clearing_tolerance with
  | MINUS -> let buy_vol = volumes.buy_minus_volume + volumes.buy_exact_volume + volumes.buy_plus_volume in
             (buy_vol, volumes.sell_minus_volume)
  | EXACT -> let buy_vol = volumes.buy_exact_volume + volumes.buy_plus_volume in
             let sell_vol = volumes.sell_minus_volume + volumes.sell_exact_volume in
             (buy_vol, sell_vol)
  | PLUS -> let sell_vol = volumes.sell_minus_volume + volumes.sell_exact_volume + volumes.sell_plus_volume in
            (volumes.buy_plus_volume, sell_vol)

[@inline]
let compute_equivalent_amount (amount : nat) (rate : exchange_rate) (invert: bool) : nat =
  let float_amount = Rational.new (int (amount)) in
  if invert then
    Math.get_rounded_number_lower_bound (Rational.div float_amount rate.rate)
  else
    Math.get_rounded_number_lower_bound (Rational.mul float_amount rate.rate)

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

  let clearing = Math.get_clearing_price rate buy_side sell_side in
  let with_equiv = build_equivalence volumes clearing rate in
  with_equiv
