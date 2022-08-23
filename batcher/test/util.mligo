#import "../batcher.mligo" "Batcher"
#import "../../breathalyzer/lib/lib.mligo" "Breath"
#import "../storage.mligo" "CommonStorage"
#import "../types.mligo" "CommonTypes"
#import "../batch.mligo" "Batch"

type originated = Breath.Contract.originated

type storage  = Batcher.storage
type result = Batcher.result

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
  let valid_swaps = (Map.empty : CommonStorage.Types.valid_swaps)
  in
  let rates_current = (Big_map.empty : CommonStorage.Types.rates_current) in
  let rates_historic = (Big_map.empty : CommonStorage.Types.rates_historic) in
  (* FIXME a treasury is not a big map *)
  let treasury = (Big_map.empty : (CommonTypes.Types.treasury)) in
  let batches = Batch.new_batch_set in
  {
    valid_tokens = valid_tokens;
    valid_swaps = valid_swaps;
    rates_current = rates_current;
    rates_historic = rates_historic;
    treasury = treasury;
    batches = batches;
  }

let originate (level: Breath.Logger.level) =
  Breath.Contract.originate
    level
    "batcher_sc"
    Batcher.main
    initial_storage
    (0tez)

let deposit (order : CommonTypes.Types.swap_order) (storage : storage) () : result =
  Batcher.deposit order storage
