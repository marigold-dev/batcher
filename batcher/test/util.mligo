#import "../batcher.mligo" "Batcher"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "../storage.mligo" "CommonStorage"
#import "../types.mligo" "CommonTypes"
#import "../batch.mligo" "Batch"
#import "../orderbook.mligo" "Order"

type originated = Breath.Contract.originated

type storage  = Batcher.storage
type result = Batcher.result
type batch = CommonTypes.Types.batch
type order = CommonTypes.Types.swap_order
type side = CommonTypes.Types.side
type tolerance = CommonTypes.Types.tolerance
type swap = CommonTypes.Types.swap
type exchange_rate = CommonTypes.Types.exchange_rate

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

  let valid_swaps = (Map.empty : CommonStorage.Types.valid_swaps)
  in
  let rates_current = (Big_map.empty : CommonStorage.Types.rates_current) in
  let rates_historic = (Big_map.empty : CommonStorage.Types.rates_historic) in
  let treasury = (Big_map.empty : (CommonTypes.Types.treasury)) in
  let orders = Big_map.literal [
    ((BUY,EXACT),([] : CommonTypes.Types.swap_order list))
  ] in
  let batch = {
     started_at = (None : timestamp option);
     closed_at = (None :timestamp option);
     finalized_at = (None : timestamp option);
     status = OPEN;
     batch_rate = (None : CommonTypes.Types.exchange_rate option);
     (*Not used*)
     orders = ([] : CommonTypes.Types.swap_order list);
     treasury = treasury;
     clearing = (None : CommonTypes.Types.clearing option);
  } in
  let batches = {
    current = batch;
    awaiting_clearing = (None : batch option);
    previous = ([] : batch list)
  } in
  let batches = Batch.new_batch_set in

  {
    valid_tokens = valid_tokens;
    valid_swaps = valid_swaps;
    rates_current = rates_current;
    rates_historic = rates_historic;
    treasury = treasury;
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
  (address : address) : CommonTypes.Types.swap_order =
  let swap = swap amount in
  let now = Tezos.get_now () in
  let order : CommonTypes.Types.swap_order = {
    trader = address;
    swap = swap;
    created_at = now;
    side = side;
    tolerance = tolerance
  }
  in
  order

let make_exchange_rate (swap : swap) (rate : nat): exchange_rate =
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

let deposit (order : CommonTypes.Types.swap_order)
  (contract : (Batcher.entrypoint, Batcher.storage) originated)
  (qty: tez)
  () =
  let deposit = Deposit order in
  Breath.Contract.transfert_to contract deposit qty