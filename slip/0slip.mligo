#import "constants.mligo" "Constants"
#import "types.mligo" "CommonTypes"
#import "storage.mligo" "CommonStorage"
#import "prices.mligo" "Pricing"


(* Use common contract storage *)
type storage  = CommonStorage.Types.t

type result = (operation list) * storage

let no_op (s : storage) : result =  (([] : operation list), s)


(*
Entrypoints:
- Swap A of X token to Y token
- Update prices and expire orders
*)
type parameter =
| Swap of CommonTypes.Types.swap_order
| Post of CommonTypes.Types.exchange_rate

let add_swap_order (_o : CommonTypes.Types.swap_order) (s : storage ) : result =
  let _address = Tezos.sender in
  no_op (s)



let post_rate (r : CommonTypes.Types.exchange_rate) (s : storage) : result =
  let updated_rate_storage = Pricing.Rates.post_rate (r) (s) in
  no_op (updated_rate_storage)

let main
  (p, s : parameter * storage) : result =
  match p with
   Swap (o) -> add_swap_order (o) (s)
   | Post(r) -> post_rate (r) (s)


