#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../common/helpers.mligo" "Helpers"
#import "../../../batcher.mligo" "Batcher"

type side = Batcher.side
type tolerance = Batcher.tolerance

let deposit_fail_no_token_allowance =
  Breath.Model.case
  "test deposit"
  "should fail if token allowance has not been made"
    (fun (level: Breath.Logger.level) ->
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in
      let contracts = Helpers.originate level btc_trader usdt_trader eurl_trader in

      let bstorage = Breath.Contract.storage_of contracts.batcher in

      let act_deposit = Helpers.place_order btc_trader contracts.batcher bstorage.fee_in_mutez "tzBTC" "USDT" 200000n Buy Exact bstorage.valid_tokens in

      let bstorage = Breath.Contract.storage_of contracts.batcher in
      let bbalance = Breath.Contract.balance_of contracts.batcher in

      Breath.Result.reduce [
        Breath.Expect.fail_with_message "NotEnoughAllowance" act_deposit
        ; Breath.Assert.is_equal "balance" bbalance 0tez
        ; Helpers.expect_last_order_number bstorage 0n
      ])

let vanilla_deposit_should_succeed =
  Breath.Model.case
  "test deposit"
  "should be successful"
    (fun (level: Breath.Logger.level) ->
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in
      let contracts = Helpers.originate level btc_trader usdt_trader eurl_trader in

      let bstorage = Breath.Contract.storage_of contracts.batcher in

      let deposit_amount = 2000000n in
      let allowance = {
        spender = contracts.batcher;
        value = deposit_amount
       } in
      let act_allow_transfer =   Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_with_entrypoint_to contracts.tzbtc "Approve" allowance 0tez)) in
      let act_deposit = Helpers.place_order btc_trader contracts.batcher bstorage.fee_in_mutez "tzBTC" "USDT" deposit_amount Buy Exact bstorage.valid_tokens in

      let bstorage = Breath.Contract.storage_of contracts.batcher in
      let bbalance = Breath.Contract.balance_of contracts.batcher in

      Breath.Result.reduce [
        act_allow_transfer
        ; act_deposit
        ; Breath.Assert.is_equal "balance" bbalance bstorage.fee_in_mutez
        ; Helpers.expect_last_order_number bstorage 1n
      ])

let test_suite =
  Breath.Model.suite "Suite for Deposits" [
    deposit_fail_no_token_allowance
    //; vanilla_deposit_should_succeed
  ]

