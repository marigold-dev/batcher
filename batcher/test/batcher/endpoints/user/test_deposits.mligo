#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../../common/helpers.mligo" "Helpers"
#import "./../../../common/batch.mligo" "Batch"
#import "../../../../batcher.mligo" "Batcher"
#import "../../../../errors.mligo" "Errors"

type skew = Batch.skew
type pressure = Batch.pressure

let deposit_fail_no_token_allowance =
  Breath.Model.case
  "test deposit"
  "should fail if token allowance has not been made"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let btc_trader = context.btc_trader in 

      let bstorage = Breath.Contract.storage_of batcher in

      let act_deposit = Helpers.place_order btc_trader batcher bstorage.fee_in_mutez "tzBTC" "USDT" 200000n Buy Exact bstorage.valid_tokens in

      let bstorage = Breath.Contract.storage_of batcher in
      let bbalance = Breath.Contract.balance_of batcher in

      Breath.Result.reduce [
        Breath.Expect.fail_with_message "NotEnoughAllowance" act_deposit
        ; Breath.Assert.is_equal "balance" bbalance 0tez
        ; Helpers.expect_last_order_number bstorage 0n
      ])

let deposit_fail_if_batch_is_closed =
  Breath.Model.case
  "test deposit"
  "should fail if batch is closed but not cleared yet"
    (fun (level: Breath.Logger.level) ->
     let pair = ("tzBTC","USDT") in
     let tick_pair = "tzBTC/USDT" in 
     let (_expected_tolerance, batch) = Batch.prepare_closed_batch pair Buy Balanced in
     let context = Helpers.test_context_with_batch tick_pair batch level in 
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

      let bstorage = Breath.Contract.storage_of batcher in
      let bbalance = Breath.Contract.balance_of batcher in

      Breath.Result.reduce [
        act_allow_transfer
        ; Breath.Expect.fail_with_value Errors.no_open_batch act_deposit
        ; Breath.Assert.is_equal "balance" bbalance 0tez
        ; Helpers.expect_last_order_number bstorage 0n
      ])

let vanilla_deposit_should_succeed =
  Breath.Model.case
  "test deposit"
  "should be successful"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let btc_trader = context.btc_trader in 

      let bstorage = Breath.Contract.storage_of batcher in

      let deposit_amount = 2000000n in
      let allowance = {
        spender = batcher.originated_address;
        value = deposit_amount
       } in

      let prior_balances = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let act_allow_transfer =   Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to context.contracts.tzbtc (Approve allowance) 0tez)) in
      let act_deposit = Helpers.place_order btc_trader batcher bstorage.fee_in_mutez "tzBTC" "USDT" deposit_amount Buy Exact bstorage.valid_tokens in

      let bstorage = Breath.Contract.storage_of batcher in
      let bbalance = Breath.Contract.balance_of batcher in
      let post_balances = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let expected_prior_balance = 90000000000n in
      let expected_post_balance = abs (expected_prior_balance - deposit_amount) in
   
      Breath.Result.reduce [
        act_allow_transfer
        ; act_deposit
        ; Breath.Assert.is_equal "balance" bbalance bstorage.fee_in_mutez
        ; Breath.Assert.is_equal "tzbtc balance prior" prior_balances.tzbtc expected_prior_balance
        ; Breath.Assert.is_equal "tzbtc balance post" post_balances.tzbtc expected_post_balance
        ; Helpers.expect_last_order_number bstorage 1n
      ])

let deposit_with_incorrect_side_should_fail =
  Breath.Model.case
  "test deposit"
  "should be successful"
    (fun (level: Breath.Logger.level) ->
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
      let act_deposit = Helpers.place_order btc_trader batcher bstorage.fee_in_mutez "tzBTC" "USDT" deposit_amount Sell Exact bstorage.valid_tokens in
   
      Breath.Result.reduce [
        act_allow_transfer
        ; Breath.Expect.fail_with_value Errors.incorrect_side_specified act_deposit
      ])

let test_suite =
  Breath.Model.suite "Suite for Deposits" [
    deposit_fail_no_token_allowance
    ; vanilla_deposit_should_succeed
    ; deposit_fail_if_batch_is_closed
    ; deposit_with_incorrect_side_should_fail

  ]

