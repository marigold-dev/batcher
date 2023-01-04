#import "types.mligo" "CommonTypes"
#import "utils.mligo" "Utils"
#import "errors.mligo" "Errors"
#import "types.mligo" "CommonTypes"
#import "math.mligo" "Math"
#import "../math_lib/lib/rational.mligo" "Rational"
#import "treasury.mligo" "Treasury"
#import "constants.mligo" "Constants"

type order = CommonTypes.Types.swap_order
type side = CommonTypes.Types.side
type tolerance = CommonTypes.Types.tolerance
type clearing = CommonTypes.Types.clearing
type exchange_rate = CommonTypes.Types.exchange_rate
type t = CommonTypes.Types.orderbook
let empty () : t = Big_map.empty


[@inline]
let compute_equivalent_amount (amount : nat) (exchange_rate : exchange_rate) (invert: bool) : nat =
  let float_amount = Rational.new (int (amount)) in
  if invert then
    Math.get_rounded_number_lower_bound (Rational.div float_amount exchange_rate.rate)
  else
    Math.get_rounded_number_lower_bound (Rational.mul float_amount exchange_rate.rate)

[@inline]
let compute_equivalent_token (order : order) (exchange_rate : exchange_rate) : nat =
  let float_amount = Rational.new (int (order.swap.from.amount)) in
  if order.swap.from.token = exchange_rate.swap.from.token then
    Math.get_rounded_number_lower_bound (Rational.mul float_amount exchange_rate.rate)
  else
    Math.get_rounded_number_lower_bound (Rational.div float_amount exchange_rate.rate)

[@inline]
let make_new_order (order : order) (amt: nat) : order =
  let new_token_amount =
    {order.swap.from with amount = amt} in
  let new_swap = {order.swap with from = new_token_amount} in
  {order with swap = new_swap}

