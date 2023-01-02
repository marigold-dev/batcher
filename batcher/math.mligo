#import "types.mligo" "CommonTypes"
#import "constants.mligo" "Constants"
#import "../math_lib/lib/rational.mligo" "Rational"

type exchange_rate = CommonTypes.Types.exchange_rate


module Types = CommonTypes.Types

module RationalUtils = struct

[@inline]
let gt (a : Rational.t) (b : Rational.t) : bool = not (Rational.lte a b)

[@inline]
let gte (a : Rational.t) (b : Rational.t) : bool = not (Rational.lt a b)

end


(* Get the number with 0 decimal accuracy *)
let get_rounded_number_lower_bound (number : Rational.t) : nat =
  let zero_decimal_number = Rational.resolve number 0n in
    abs (zero_decimal_number)


let get_min_number (a : Rational.t) (b : Rational.t) =
  if Rational.lte a b then a
  else b

let get_clearing_tolerance (cp_minus : Rational.t) (cp_exact : Rational.t) (cp_plus : Rational.t) : Types.tolerance =
  if (RationalUtils.gte cp_minus cp_exact) && (RationalUtils.gte cp_minus cp_plus) then MINUS
  else if (RationalUtils.gte cp_exact cp_minus) && (RationalUtils.gte cp_exact cp_plus) then EXACT
  else PLUS

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
    prorata_equivalence = CommonTypes.Utils.empty_prorata_equivalence;
    clearing_rate = exchange_rate
  }
