#import "../batcher.mligo" "Batcher"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "../storage.mligo" "CommonStorage"
#import "../types.mligo" "CommonTypes"
#import "../batch.mligo" "Batch"
#import "../orderbook.mligo" "Order"
#import "../../math_lib/lib/float.mligo" "Float"

module Types = CommonTypes.Types

type originated = Breath.Contract.originated

type storage  = Batcher.storage
type result = Batcher.result
type order = CommonTypes.Types.external_swap_order
type side = CommonTypes.Types.side
type tolerance = CommonTypes.Types.tolerance
type swap = CommonTypes.Types.swap
type exchange_rate = CommonTypes.Types.exchange_rate
type treasury = CommonTypes.Types.treasury
type swap_order = CommonTypes.Types.swap_order
type external_swap_order = CommonTypes.Types.external_swap_order


let token_USDT = {
  name = "USDT";
  address = Some(("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address));
}

let token_XTZ = {
   name = "XTZ";
   address = (None : address option);
   decimals = 6
}

let token_USDT = {
  name = "USDT";
  address = Some(("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address));
  decimals = 6
}

let token_tzBTC = {
   name = "tzBTC";
   address = Some(("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address));
   decimals = 8
}

let initial_storage : Batcher.storage =
  let valid_tokens = [
    token_USDT;
    token_tzBTC
  ]
  in
  (* TODO? I think this is obsolete but I'm not sure; discuss
in review *)
  (* Jason's example seems to consider that valid_swaps are the
     swaps that the user/the DEX are allowed to make,
     but the type does not match this usage. *)
  let valid_swaps = (Map.empty : CommonStorage.Types.valid_swaps)
  in
  let rates_current = (Big_map.empty : CommonStorage.Types.rates_current) in
  (* FIXME a treasury is not a big map *)
  let batches = Batch.new_batch_set in
  {
    valid_tokens = valid_tokens;
    valid_swaps = valid_swaps;
    rates_current = rates_current;
    batches = batches;
  }

let default_swap (amount : nat) = {
  from = {
    token = token_tzBTC;
    amount = amount
  };
  to = token_USDT
}

let make_order (side : side) (tolerance : tolerance) (swap : nat -> CommonTypes.Types.swap) (amount : nat)
  (address : address) : swap_order =
  let swap = swap amount in
  let now = Tezos.get_now () in
  let order : swap_order = {
    trader = address;
    swap = swap;
    created_at = now;
    side = side;
    tolerance = tolerance
  }
  in
  order

let to_external_side (side:side) : nat = 
    match side with
    | BUY -> 0n
    | SELL -> 1n

let to_external_tolerance (tolerance:tolerance) : nat =
    match tolerance with
    | MINUS -> 0n
    | EXACT -> 1n
    | PLUS -> 2n

let to_external_order (order: swap_order) : external_swap_order = 
  let order : external_swap_order = {
    trader = order.trader;
    swap = order.swap;
    created_at = order.created_at;
    side = to_external_side(order.side);
    tolerance = to_external_tolerance(order.tolerance)
  }
  in
  order

let make_external_order (side : side) (tolerance : tolerance) (swap : nat -> swap) (amount : nat)
  (address : address) : external_swap_order =
  let internal = make_order (side) (tolerance) (swap) (amount) (address) in
  to_external_order(internal)

let make_exchange_rate (swap : swap) (rate : Float.t): exchange_rate =
  {
    swap = swap;
    rate = rate;
    when = Tezos.get_now ()
  }

let originate (level: Breath.Logger.level) =
  Breath.Contract.originate
    level
    "batcher_sc"
    Batcher.main
    initial_storage
    (0tez)

let deposit (order : order)
  (contract : (Batcher.entrypoint, Batcher.storage) originated)
  (qty: tez)
  () =
  let deposit = Deposit order in
  Breath.Contract.transfert_to contract deposit qty
