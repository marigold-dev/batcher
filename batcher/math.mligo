#import "types.mligo" "CommonTypes"
#import "../math_lib/lib/float.mligo" "Float"

module Types = CommonTypes.Types

let constant_number = Float.add (Float.new 1 0) (Float.inverse (Float.new 10 4))

let get_min_number (a : Float.t) (b : Float.t) = 
  if Float.lte a b then a 
  else b 

let get_clearing_tolerance (cp_minus : Float.t) (cp_exact : Float.t) (cp_plus : Float.t) : Types.tolerance =  
  if (Float.gte cp_minus cp_exact) && (Float.gte cp_minus cp_plus) then MINUS
  else if (Float.gte cp_exact cp_minus) && (Float.gte cp_exact cp_plus) then EXACT
  else if (Float.gte cp_plus cp_exact) && (Float.gte cp_plus cp_exact) then PLUS
  else PLUS

let get_cp_minus (oracle_price : Float.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Float.t = 
  let (buy_minus_token, buy_exact_token, buy_plus_token) = buy_side in
  let (sell_minus_token, _, _) = sell_side in 
  let left_number = Float.new (buy_minus_token + buy_exact_token + buy_plus_token) 0 in
  let right_number = Float.div (Float.mul (Float.new sell_minus_token 0) constant_number) oracle_price in 
  let min_number = get_min_number left_number right_number in 
  min_number

let get_cp_exact (oracle_price : Float.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Float.t = 
  let (_, buy_exact_token, buy_plus_token) = buy_side in 
  let (sell_minus_token, sell_exact_token, _) = sell_side in 
  let left_number = Float.new (buy_exact_token + buy_plus_token) 0 in 
  let right_number = Float.div (Float.new (sell_minus_token + sell_exact_token) 0) oracle_price in 
  let min_number = get_min_number left_number right_number in 
  min_number

let get_cp_plus (oracle_price : Float.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Float.t = 
  let (_, _, buy_plus_token) = buy_side in 
  let (sell_minus_token, sell_exact_token, sell_plus_token) = sell_side in 
  let left_number = Float.new buy_plus_token 0 in 
  let right_number = Float.div (Float.new (sell_minus_token + sell_exact_token + sell_plus_token) 0) (Float.mul constant_number oracle_price) in 
  let min_number = get_min_number left_number right_number in 
  min_number

let get_clearing_price (oracle_price : Float.t) (buy_side : Types.buy_side) (sell_side : Types.sell_side) : Types.clearing = 
  let cp_minus = get_cp_minus oracle_price buy_side sell_side in 
  let cp_exact = get_cp_exact oracle_price buy_side sell_side in 
  let cp_plus = get_cp_plus oracle_price buy_side sell_side in 
  let clearing_volumes =
    Map.literal [
      (MINUS, cp_minus);
      (EXACT, cp_exact);
      (PLUS, cp_minus)
    ] 
  in
  let clearing_tolerance = get_clearing_tolerance cp_minus cp_exact cp_plus in 
  { clearing_volumes = clearing_volumes; clearing_tolerance = clearing_tolerance }