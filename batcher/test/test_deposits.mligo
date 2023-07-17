#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./common/helpers.mligo" "Helpers"
#import "../batcher.mligo" "Batcher"

type side = Batcher.side
type tolerance = Batcher.tolerance

let vanilla_deposit =
  Breath.Model.case
  "test deposit"
  "should be successful"
    (fun (level: Breath.Logger.level) ->
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in
      let contracts = Helpers.originate level btc_trader usdt_trader eurl_trader in

      let bstorage = Breath.Contract.storage_of contracts.batcher in

      let act_deposit = Helpers.place_order btc_trader contracts.batcher bstorage.fee_in_mutez "tzBTC" "USDT" 200000n Buy Exact bstorage.valid_tokens in

      let bstorage = Breath.Contract.storage_of contracts.batcher in
      let bbalance = Breath.Contract.balance_of contracts.batcher in

      Breath.Result.reduce [
        act_deposit
        ; act_deposit
        ; Breath.Assert.is_equal "balance" bbalance bstorage.fee_in_mutez
        ; Helpers.expect_last_order_number bstorage 1n
      ])

let test_suite =
  Breath.Model.suite "Suite for Deposits" [
    vanilla_deposit
  ]

