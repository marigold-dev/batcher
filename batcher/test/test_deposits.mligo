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
      let (_, (alice, bob, carol)) = Breath.Context.init_default () in

      let contract = Helpers.originate_with_rate level "tzBTC/USDT" "USDT" "tzBTC" 30000n in

      let storage = Breath.Contract.storage_of contract in

      let act_deposit = Helpers.place_order alice contract storage.fee_in_mutez "tzBTC" "USDT" 200000n Buy Exact storage.valid_tokens in

      let storage = Breath.Contract.storage_of contract in
      let balance = Breath.Contract.balance_of contract in

      Breath.Result.reduce [
        act_deposit
        ; act_deposit
        ; Breath.Assert.is_equal "balance" balance storage.fee_in_mutez
        ; Helpers.expect_last_order_number storage 1n
      ])

let test_suite =
  Breath.Model.suite "Suite for Deposits" [
    vanilla_deposit
  ]

