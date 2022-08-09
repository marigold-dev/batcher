#import "../commons/constants.mligo" "Constants"
#import "../commons/types.mligo" "CommonTypes"
#import "../commons/storage.mligo" "CommonStorage"
#import "../prices/prices.mligo" "Pricing"
#import "../treasury/treasury.mligo" "Treasury"
#import "../order_matching/order_match.mligo" "Matching"


(* Use common contract storage *)
type storage  = CommonStorage.Types.t

type result = (operation list) * storage

let no_op (s : storage) : result =  (([] : operation list), s)

(* The immediate address: 
  - Store the deposited tokens  
  - Redeem the tokens to the original address
*)
let immediate_address = ("tz1Kt9BvHop6XKBvZFTy6FhM8VrzQPTRbipB" : address)

(*
Entrypoints:
- Swap A of X token to Y token
- Update prices and expire orders
- a tick for triggering the matching algorithm
*)
type parameter =
| Swap of CommonTypes.Types.swap_order
| Post of CommonTypes.Types.exchange_rate
| Tick

let add_swap_order (o : CommonTypes.Types.swap_order) (s : storage ) : result =
  let address = Tezos.sender in
  let deposited_token : CommonTypes.Types.token_amount =  {
         token = o.swap.from;
         amount = o.from_amount;
     } in
  let deposit : CommonTypes.Types.deposit = {
     deposited_token_amount = deposited_token_amount;
     exchange_rate = rate;
  }  in
  let s = Treasury.Utils.deposit address deposit s in
  let orderbook = s.orderbook in
  let new_orderbook = Matching.pushOrder o orderbook (o.swap.from.name, o.swap.to.name) in
  ([], {s with orderbook = new_orderbook})

let expire_orders (s : storage) : storage = s

let post_rate (r : CommonTypes.Types.exchange_rate) (s : storage) : result =
  let updated_rate_storage = Pricing.Rates.post_rate (r) (s) in
  let new_storage = trigger_order_matching_computation s in
  no_op (new_storage)

let trigger_order_matching_computation (storage : storage) : storage =
  let orderbook = storage.orderbook in
  let new_orderbook Matching.match_orders orderbook in
  {storage with orderbook = new_orderbook}

let main
  (p, s : parameter * storage) : result =
  let s = expire_orders (s) in
  (* let s = Matching.tick (s) in *)
  match p with
   Swap (o) -> add_swap_order (o) (s)
   | Post(r) -> post_rate (r) (s)


