#import "../batcher.mligo" "Batcher"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "../storage.mligo" "CommonStorage"
#import "../types.mligo" "CommonTypes"

#import "../batch.mligo" "Batch"
#import "../orderbook.mligo" "Order"

module Types = Types.Types

type originated = Breath.Contract.originated

type storage  = Batcher.storage
type result = Batcher.result
type order = Types.swap_order


let token_USDT = {
  name = "USDT";
  address = Some(("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address));
}

let token_XTZ = {
   name = "XTZ";
   address = (None : address option);
}

(* Not used in v1 *)
let token_tzBTC = {
   name = "tzBTC";
   address = Some(("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address));
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
  let valid_swaps = (Map.empty : Storage.Types.valid_swaps)
  in
  let rates_current = (Big_map.empty : Storage.Types.rates_current) in
  let rates_historic = (Big_map.empty : Storage.Types.rates_historic) in
  (* FIXME a treasury is not a big map *)
  let treasury = (Big_map.empty : (Types.treasury)) in
  let batches = Batch.new_batch_set in
  let orders = Big_map.literal [
    ((BUY,EXACT),([] : CommonTypes.Types.swap_order list))
  ] in

  {
    valid_tokens = valid_tokens;
    valid_swaps = valid_swaps;
    rates_current = rates_current;
    rates_historic = rates_historic;
    batches = batches;
    orders = orders
  }

let default_swap (amount : nat) = {
  from = {
    token = token_tzBTC;
    amount = amount
  };
  to = token_USDT
}

let make_order (swap : nat -> CommonTypes.Types.swap) (amount : nat)
  (address : address) : CommonTypes.Types.swap_order =
  let swap = swap amount in
  let now = Tezos.get_now () in
  let order : CommonTypes.Types.swap_order = {
    trader = address;
    swap = swap;
    created_at = now;
    side = BUY;
    tolerance = EXACT
  }
  in
  order

let default_swap (amount : nat) = {
  from = {
    token = token_tzBTC;
    amount = amount
  };
  to = token_USDT
}

let make_order (swap : nat -> Types.swap) (amount : nat)
  (address : address) : Types.swap_order =
  let swap = swap amount in
  let now = Tezos.get_now () in
  let order : Types.swap_order = {
    trader = address;
    swap = swap;
    created_at = now;
    side = BUY;
    tolerance = EXACT
  }
  in
  order

let originate (level: Breath.Logger.level) =
  Breath.Contract.originate
    level
    "batcher_sc"
    Batcher.main
    initial_storage
    (0tez)

let deposit (order : Types.swap_order)
  (contract : (Batcher.entrypoint, Batcher.storage) originated)
  (qty: tez)
  () =
  let deposit = Deposit order in
  Breath.Contract.transfert_to contract deposit qty