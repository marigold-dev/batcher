#include "../commons/types.mligo"
#include "../commons/constants.mligo"
#import "../commons/types.mligo" "CommonTypes"
#import "../commons/storage.mligo" "CommonStorage"

(* Use common contract storage *)
let storage  = CommonStorage.t;

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

let expire_orders (s : storage) : storage = s


let post_price (_price, storage: CommonTypes.price * storage) : result = no_op ()

let main (p, s : parameter * storage) : result =
 let s = expire_orders s in
 match p with
   Swap (o) -> add_order (o,s)
 | Update   -> no_op (s)
 | Post(pr) -> post_price (pr,s)
