#import "types.mligo" "CommonTypes"
#import "../math_lib/lib/float.mligo" "Float"

module Types = CommonTypes.Types

let constant_number = Float.add (Float.new 1 0) (Float.new 1 (-4))

(* Get the number with 0 decimal accuracy *)
let get_rounded_number (number : Float.t) : nat = 
  let one_decimal_number = Float.resolve number 1n in 
  let zero_decimal_number = Float.resolve number 0n in 
  if (one_decimal_number - zero_decimal_number * 10) < 5 then 
    abs (zero_decimal_number)
  else 
    abs (zero_decimal_number + 1) 


let get_min_number (a : Float.t) (b : Float.t) = 
  if Float.lte a b then a 
  else b 

let get_clearing_tolerance (cp_minus : Float.t) (cp_exact : Float.t) (cp_plus : Float.t) : Types.tolerance =  
  if (Float.gte cp_minus cp_exact) && (Float.gte cp_minus cp_plus) then MINUS
  else if (Float.gte cp_exact cp_minus) && (Float.gte cp_exact cp_plus) then EXACT
  else PLUS

let get_cp_minus (rate : Float.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Float.t = 
  let (buy_minus_token, buy_exact_token, buy_plus_token) = buy_side in
  let (sell_minus_token, _, _) = sell_side in 
  let left_number = Float.new (buy_minus_token + buy_exact_token + buy_plus_token) 0 in
  let right_number = Float.div (Float.mul (Float.new sell_minus_token 0) constant_number) rate in 
  let min_number = get_min_number left_number right_number in 
  min_number

let get_cp_exact (rate : Float.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Float.t = 
  let (_, buy_exact_token, buy_plus_token) = buy_side in 
  let (sell_minus_token, sell_exact_token, _) = sell_side in 
  let left_number = Float.new (buy_exact_token + buy_plus_token) 0 in 
  let right_number = Float.div (Float.new (sell_minus_token + sell_exact_token) 0) rate in 
  let min_number = get_min_number left_number right_number in 
  min_number

let get_cp_plus (rate : Float.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Float.t = 
  let (_, _, buy_plus_token) = buy_side in 
  let (sell_minus_token, sell_exact_token, sell_plus_token) = sell_side in 
  let left_number = Float.new buy_plus_token 0 in 
  let right_number = Float.div (Float.new (sell_minus_token + sell_exact_token + sell_plus_token) 0) (Float.mul constant_number rate) in 
  let min_number = get_min_number left_number right_number in 
  min_number

let get_clearing_price (rate : Float.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Types.clearing = 
  let cp_minus = get_cp_minus rate buy_side sell_side in 
  let cp_exact = get_cp_exact rate buy_side sell_side in 
  let cp_plus = get_cp_plus rate buy_side sell_side in 
  let rounded_cp_minus = get_rounded_number cp_minus in 
  let rounded_cp_exact = get_rounded_number cp_exact in 
  let rounded_cp_plus = get_rounded_number cp_plus in 
  let clearing_volumes =
    Map.literal [
      (MINUS, rounded_cp_minus);
      (EXACT, rounded_cp_exact);
      (PLUS, rounded_cp_plus)
    ] 
  in
  let clearing_tolerance = get_clearing_tolerance cp_minus cp_exact cp_plus in 
  { clearing_volumes = clearing_volumes; clearing_tolerance = clearing_tolerance }