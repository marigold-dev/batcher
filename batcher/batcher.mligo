#import "constants.mligo" "Constants"
#import "types.mligo" "CommonTypes"
#import "storage.mligo" "CommonStorage"
#import "prices.mligo" "Pricing"
#import "math.mligo" "Math"
#import "clearing.mligo" "Clearing"

type storage  = CommonStorage.Types.t
type result = (operation list) * storage


let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
| Deposit of CommonTypes.Types.swap_order
| Post of CommonTypes.Types.exchange_rate
| Tick

let deposit (order: CommonTypes.Types.swap_order) (storage : storage) : result =
    let _key = (order.side, order.tolerance) in
    let _amount_deposited = order.swap.from.amount in
    no_op (storage)

let has_passed_window (ts: timestamp option) (interval : int) : bool =
    match ts with
    | Some t ->  t + interval < Tezos.now
    | None -> false

let finalize_batch (batches : CommonTypes.Types.batches) : CommonTypes.Types.batches =
    batches


let check_and_finalize_batch (ac: CommonTypes.Types.batch) (batches : CommonTypes.Types.batches) : CommonTypes.Types.batches =
  let finalise = has_passed_window (ac.closed_at) (Constants.price_wait_window) in
  if finalise then  finalize_batch batches else batches

let post_rate (rate : CommonTypes.Types.exchange_rate) (storage : storage) : result =
  let updated_rate_storage = Pricing.Rates.post_rate rate storage in
  let updated_batches = (match storage.batches.awaiting_clearing with
  | None -> storage.batches
  | Some (ac) -> check_and_finalize_batch (ac) (storage.batches)) in
  no_op ({ updated_rate_storage with batches = updated_batches } )


let has_deposit_window_ended( batch : CommonTypes.Types.batch ) : bool =
   match batch.status with
   | OPEN -> has_passed_window batch.started_at Constants.deposit_time_window
   | _ -> false



let close_current_batch (batches : CommonTypes.Types.batches) : CommonTypes.Types.batches =
   let current_batch = batches.current in
   if (has_deposit_window_ended current_batch) then
         let closed_batch = { current_batch with status = CLOSED; closed_at = Some(Tezos.now)  } in
         let new_current_batch =  CommonTypes.Utils.get_new_current_batch in
         { batches with current = new_current_batch; awaiting_clearing = Some(closed_batch);  }
    else
      batches


let check_batches (storage : storage ) : storage =
   let batches = storage.batches in
   let updated_batches = (match batches.awaiting_clearing with
                          | None -> close_current_batch batches
                          | Some (ac) -> batches) in
   { storage with batches = updated_batches}


let tick (storage : storage) : result =
    let updated_storage = check_batches storage in
    no_op (updated_storage)

let main
  (action, storage : entrypoint * storage) : result =
  match action with
   | Deposit order  -> deposit order storage
   | Post new_rate -> post_rate new_rate storage
   | Tick -> tick storage

