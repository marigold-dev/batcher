#include "../commons/types.mligo"
#include "../commons/constants.mligo"

let no_op (s : storage) : result =  (([] : operation list), s)

(*
Entrypoints:
- Swap A of X token to Y token
- Update prices and expire orders
*)
type parameter =
  Swap of swap_x_to_y_param
| Update

let add_order (_o,s : swap_x_to_y_param * storage ) : result = no_op (s)

let update_prices (s : storage) : storage = s

let expire_orders (s : storage) : storage = s

let update_prices_and_expire_orders (s : storage) : storage =
    let s = update_prices s in
    let s = expire_orders s in
    s


let main (p, s : parameter * storage) : result =
 let s = update_prices_and_expire_orders s in
 match p with
   Swap (o) -> add_order (o,s)
 | Update   -> no_op (s)
