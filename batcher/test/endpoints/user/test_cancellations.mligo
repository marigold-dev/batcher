#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../common/helpers.mligo" "Helpers"
#import "./../../common/batch.mligo" "Batch"
#import "../../../batcher.mligo" "Batcher"

type skew = Batch.skew
type pressure = Batch.pressure

let cancellation_fail_if_batch_is_closed =
  Breath.Model.case
  "test cancellation"
  "should fail if batch is closed"
    (fun (level: Breath.Logger.level) ->
     let pair = ("tzBTC","USDT") in
     let tick_pair = "tzBTC/USDT" in 
     let (_expected_tolerance, batch) = Batch.prepare_closed_batch pair Buy Balanced in
     let context = Helpers.test_context_with_batch tick_pair batch level in 
     let batcher = context.contracts.batcher in 
     let btc_trader = context.btc_trader in 

      let act_cancel = Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Cancel pair) 0tez)) in

      Breath.Result.reduce [
        Breath.Expect.fail_with_value Batcher.cannot_cancel_orders_for_a_batch_that_is_not_open act_cancel
      ])

let cancellation_should_succeed =
  Breath.Model.case
  "test cancellation"
  "should be successful"
    (fun (level: Breath.Logger.level) ->
     let pair = ("tzBTC","USDT") in
     let tick_pair = "tzBTC/USDT" in 
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let btc_trader = context.btc_trader in 

      let bstorage = Breath.Contract.storage_of batcher in

      let deposit_amount = 2000000n in
      let allowance = {
        spender = batcher.originated_address;
        value = deposit_amount
       } in
      let act_allow_transfer =   Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to context.contracts.tzbtc (Approve allowance) 0tez)) in
      let act_deposit = Helpers.place_order btc_trader batcher bstorage.fee_in_mutez "tzBTC" "USDT" deposit_amount Buy Exact bstorage.valid_tokens in

      let bstorage_after_desposit = Breath.Contract.storage_of batcher in
      let batch_after_deposit = Option.unopt (Helpers.get_current_batch tick_pair bstorage_after_desposit) in
      let total_volumes_after_deposit = batch_after_deposit.volumes.buy_total_volume + batch_after_deposit.volumes.sell_total_volume in
      let holdings_after_deposit = batch_after_deposit.holdings in 

      let act_cancel = Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Cancel pair) 0tez)) in

      let bstorage_after_cancellation = Breath.Contract.storage_of batcher in
      let batch_after_cancellation = Option.unopt (Helpers.get_current_batch tick_pair bstorage_after_cancellation) in
      let total_volumes_after_cancellation = batch_after_cancellation.volumes.buy_total_volume + batch_after_deposit.volumes.sell_total_volume in
      let holdings_after_cancellation = batch_after_cancellation.holdings in 

      Breath.Result.reduce [
        act_allow_transfer
        ; act_deposit
        ; Helpers.expect_last_order_number bstorage_after_desposit 1n
        ; Breath.Assert.is_equal "holdings after deposit" holdings_after_deposit 1n
        ; Breath.Assert.is_equal "total volumes after deposit" total_volumes_after_deposit 2000000n
        ; act_cancel
        ; Breath.Assert.is_equal "holdings after cancellation" holdings_after_cancellation 0n
        ; Breath.Assert.is_equal "total volumes after cancellation" total_volumes_after_cancellation 0n
        ; Helpers.expect_last_order_number bstorage_after_cancellation 1n   (* We do not decrement the last order number on cancellations *)
      ])

let test_suite =
  Breath.Model.suite "Suite for Cancellations" [
    cancellation_fail_if_batch_is_closed
    ; cancellation_should_succeed
  ]

