#import "constants.mligo" "Constants"
#import "types.mligo" "CommonTypes"
#import "storage.mligo" "CommonStorage"
#import "prices.mligo" "Pricing"
#import "math.mligo" "Math"
#import "clearing.mligo" "Clearing"
#import "batch.mligo" "Batch"

type storage  = CommonStorage.Types.t
type result = (operation list) * storage

let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
  | Deposit of CommonTypes.Types.swap_order
  | Post of CommonTypes.Types.exchange_rate
  | Tick

let finalize (batch : Batch.t) (storage : storage) (current_time : timestamp) : Batch.t =
  let rate_name = CommonTypes.Utils.get_rate_name_from_pair batch.pair in
  let rate =
    match Big_map.find_opt rate_name storage.rates_current with
        | None -> (failwith Pricing.PriceErrors.no_rate_available_for_swap : CommonTypes.Types.exchange_rate)
        | Some r -> r
  in
  let clearing = Clearing.compute_clearing_prices rate storage in
  Batch.finalize batch current_time clearing rate

let tick_current_batches (storage : storage) : storage =
  let batches = storage.batches in
  let updated_batches =
    match batches.current with
      | None ->
        batches
      | Some batch ->
        let current_time = Tezos.get_now () in
        let batch =
          if Batch.should_be_closed batch current_time then
            Batch.close batch current_time
          else if Batch.should_be_cleared batch current_time then
            (* Finalize the current batch, but does not open a new one before we receive
               a new deposit *)
            finalize batch storage current_time
          else
            batch
        in
        { batches with current = Some batch }
  in
  { storage with batches = updated_batches }

let try_to_append_order (order : CommonTypes.Types.swap_order)
  (batches : Batch.batch_set) : Batch.batch_set =
  match batches.current with
    | None ->
      failwith "Append an order with no current batch" (* FIXME: make this impossible *)
    | Some current ->
      if not (Batch.is_open current) then
        failwith "Append an order to a non open batch"
      else
        let current = Batch.append_order order current in
        { batches with current = Some current }

(* Register a deposit during a valid (Open) deposit time; fails otherwise.
   Updates the current_batch if the time is valid but the new batch was not initialized. *)
let deposit (order: CommonTypes.Types.swap_order) (storage : storage) : result =
  let _key = (order.side, order.tolerance) in
  let _amount_deposited = order.swap.from.amount in
  let storage = tick_current_batches storage in
  let current_time = Tezos.get_now () in
  let updated_batches =
    if Batch.should_open_new storage.batches current_time then
      let treasury = storage.treasury in
      Batch.start_period order storage.batches current_time treasury
    else
      try_to_append_order order storage.batches
  in
  let storage = { storage with batches = updated_batches } in
  no_op (storage)

(* Post the rate in the contract and check if the current batch of orders needs to be cleared.
   TODO: actually update the rate *)
let post_rate (rate : CommonTypes.Types.exchange_rate) (storage : storage) : result =
  let updated_rate_storage = Pricing.Rates.post_rate rate storage in
  match storage.batches.current with
    (* TODO: find a way to remove these tests? *)
    | None -> no_op (storage)
    | Some current_batch ->
      let updated_batches =
        let current_time = Tezos.get_now () in
        if Batch.should_be_cleared current_batch current_time then
          let batch = finalize current_batch storage current_time in
          { storage.batches with current = Some batch }
        else
          storage.batches
      in
        no_op ({ updated_rate_storage with batches = updated_batches } )

let tick (storage : storage) : result =
  let updated_storage = tick_current_batches storage in
  no_op (updated_storage)

let main
  (action, storage : entrypoint * storage) : result =
  match action with
   | Deposit order  -> deposit order storage
   | Post new_rate -> post_rate new_rate storage
   | Tick -> tick storage

