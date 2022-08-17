#import "constants.mligo" "Constants"
#import "types.mligo" "CommonTypes"
#import "storage.mligo" "CommonStorage"
#import "prices.mligo" "Pricing"
#import "math.mligo" "Math"

type storage  = CommonStorage.Types.t

type result = (operation list) * storage

let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
| Deposit of CommonTypes.Types.swap_order
| Post of CommonTypes.Types.exchange_rate

let update_distribution 
  (key: CommonTypes.Types.side * CommonTypes.Types.tolerance)
  (amount_deposited: nat)
  (distribution_map: CommonStorage.Types.side_tolerance_distribution)
  : CommonStorage.Types.side_tolerance_distribution
=
  match Map.get_and_update key (None : nat option)  distribution_map with
    | (None, distrib) -> Map.add key amount_deposited distrib
    | (Some(old_amount),distrib) -> Map.add key (old_amount+amount_deposited) distrib

(*we'll change all the nat type to float when we'll use the math lib of ligo*)
let update_clearing_prices 
  (datas : ((CommonTypes.Types.side * CommonTypes.Types.tolerance) * nat) list)
  (clearing_prices : CommonStorage.Types.clearing_prices) : CommonStorage.Types.clearing_prices =
  let f 
    (acc, (key,price) : CommonStorage.Types.clearing_prices * ((CommonTypes.Types.side * CommonTypes.Types.tolerance) * nat))
  =
    Map.update key (Some(Some(price))) acc
  in
  List.fold_left f clearing_prices datas


let get_distribution_of 
  (side, tolerance : CommonTypes.Types.side * CommonTypes.Types.tolerance)
  (distributions : CommonStorage.Types.side_tolerance_distribution) : nat
=
  match Map.find_opt (side, tolerance) distributions with
    | None -> failwith "key (side,tolerance should exist"
    | Some (amount_of_orders) -> amount_of_orders

let compute_clearing_prices 
  (rate: CommonTypes.Types.exchange_rate) 
  (storage : storage) : storage
=
  let exchange_rate = Pricing.Rates.get_rate rate.swap storage in
  let distributions = storage.side_tolerance_distribution in

  let sell_cp_minus = get_distribution_of (SELL,MINUS) distributions in 
  let sell_cp_exact = get_distribution_of (SELL,EXACT) distributions in 
  let sell_cp_plus = get_distribution_of (SELL,PLUS) distributions in

  let buy_cp_minus = get_distribution_of (BUY,MINUS) distributions in 
  let buy_cp_exact = get_distribution_of (BUY,EXACT) distributions in 
  let buy_cp_plus = get_distribution_of (BUY,PLUS) distributions in

  let (scm,sce,scp,bcm,bce,bcp) = 
    Math.Utils.clearing_prices
      exchange_rate.rate
      buy_cp_minus buy_cp_exact buy_cp_plus
      sell_cp_minus sell_cp_exact sell_cp_plus in

  let new_clearing_prices =
    update_clearing_prices
      [((SELL,MINUS),scm); ((SELL,EXACT),sce); ((SELL,PLUS),scp);
      ((BUY,MINUS),bcm); ((BUY,MINUS),bce); ((SELL,MINUS),bcp)]
      storage.clearing_prices
  in

  {storage with clearing_prices = new_clearing_prices}


let deposit (order: CommonTypes.Types.swap_order) (storage : storage) : result =
    let key = (order.side, order.tolerance) in
    let amount_deposited = order.swap.from.amount in
    let new_distribution = update_distribution key amount_deposited storage.side_tolerance_distribution in
    let new_storage = {storage with side_tolerance_distribution = new_distribution} in
  no_op (new_storage)


let post_rate (rate : CommonTypes.Types.exchange_rate) (storage : storage) : result =
  let updated_rate_storage = Pricing.Rates.post_rate rate storage in
  let update_clearing_prices_storage = compute_clearing_prices rate updated_rate_storage in
  
  no_op (update_clearing_prices_storage)

let main
  (action, storage : entrypoint * storage) : result =
  match action with
   | Deposit order  -> deposit order storage
   | Post new_rate -> post_rate new_rate storage


