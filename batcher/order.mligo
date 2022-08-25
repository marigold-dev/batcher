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

type key = (side * tolerance)

type t = (key, order list) big_map

let fill_order (order : order) (volume : nat) : matching * nat =
  let needed_amount = order.swap.from.amount in
  if volume = 0n then No_match,0n
  else
    if volume >= needed_amount then
      Total, abs (volume - needed_amount)
    else
      let new_token_amount = 
        {order.swap.from with amount = abs (needed_amount - volume)} in
      let new_swap = {order.swap with from = new_token_amount} in
      let new_order = {order with swap = new_swap} in
      Partial new_order,0n

let push_order (order : order) (orderbook : t) : t =
  let key = (order.side,order.tolerance) in
  let new_orderbook = 
    match Big_map.get_and_update key (None : order list option) orderbook with
    | None,orderbook -> 
       Big_map.add key [order] orderbook
    | Some(orders),orderbook -> 
       Big_map.add key (order :: orders) orderbook
  in new_orderbook