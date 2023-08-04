#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../common/utils.mligo" "Utils"
#import "./../common/batch.mligo" "Batch"
#import "../../batcher.mligo" "Batcher"
#import "./../common/helpers.mligo" "Helpers"


type batch = Batcher.batch
type tolerance = Batcher.tolerance
type skew = Batch.skew
type pressure = Batch.pressure


let clearing_test 
 (description)
 (pressure:pressure)
 (skew:skew) = 
  Breath.Model.case
  "test clearing"
  description
    (fun (level: Breath.Logger.level) ->
     let pair = ("tzBTC","USDT") in
     let tick_pair = "tzBTC/USDT" in 
     let (expected_tolerance, batch) = Batch.prepare_closed_batch pair pressure skew in
     let context = Helpers.test_context_with_batch tick_pair batch level in 
     let batcher = context.contracts.batcher in 

     let act_tick = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Tick tick_pair) 0tez)) in

     let new_storage = Breath.Contract.storage_of batcher in

     let updated_batch = Option.unopt(Big_map.find_opt 1n new_storage.batch_set.batches) in
     let  () = Breath.Logger.log level updated_batch in 
     let clearing = Option.unopt (Batcher.Ubots.get_clearing updated_batch) in 

     Breath.Result.reduce [
        act_tick
        ; Breath.Assert.is_equal "expected cleaing tolerance" expected_tolerance clearing.clearing_tolerance
     ])

let test_suite =
  Breath.Model.suite "Suite for Clearing" [
     clearing_test "Buy Pressure - No Skew" Buy NoSkew
     ; clearing_test "Buy Pressure -  No Skew" Sell NoSkew
     ; clearing_test "Buy Pressure - Balanced" Buy Balanced
     ; clearing_test "Sell Pressure -  Balanced" Sell Balanced
     ; clearing_test "Buy Pressure - Positive Skew" Buy Positive
     ; clearing_test "Buy Pressure - Negative Skew " Buy Negative
     ; clearing_test "Sell Pressure - Positive Skew" Sell Positive
     ; clearing_test "Sell Pressure - Negative Skew" Sell Negative
     ; clearing_test "Buy Pressure - Large Positive Skew" Buy LargePositive
     ; clearing_test "Buy Pressure - Large Negative Skew " Buy LargeNegative
     ; clearing_test "Sell Pressure - Large Negative Skew " Sell LargeNegative
     ; clearing_test "Sell Pressure - Large Positive Skew" Sell LargePositive
     ; clearing_test "Buy Pressure - Negative Skew - All Worse Prices" Buy NegativeAllWorse
     ; clearing_test "Buy Pressure - Negative Skew - All Better Prices" Buy NegativeAllBetter
     ; clearing_test "Sell Pressure - Positive Skew - All Worse Prices" Sell PositiveAllWorse
     ; clearing_test "Sell Pressure - Positive Skew - All Better Prices" Sell PositiveAllBetter
  ]


