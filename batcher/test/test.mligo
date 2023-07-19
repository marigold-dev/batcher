#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./common/helpers.mligo" "Helpers"
#import "./endpoints/user/test_deposits.mligo" "User_Deposits"
#import "./endpoints/user/test_redemptions.mligo" "User_Redemptions"
#import "./economics/test_clearing.mligo" "Economics_Clearing"
#import "./endpoints/admin/test_change_fee.mligo" "Admin_Change_Fee"


let contract_can_be_originated =
  Breath.Model.case
  "test contract"
  "can be originated"
    (fun (level: Breath.Logger.level) ->
      let () = Breath.Logger.log level "Originate Batcher contract" in
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in
      let contracts = Helpers.originate level btc_trader usdt_trader eurl_trader in
      let batcher_storage = Breath.Contract.storage_of contracts.batcher in
      let batcher_balance = Breath.Contract.balance_of contracts.batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "balance" batcher_balance 0tez
      ; Helpers.expect_last_order_number batcher_storage 0n
      ])


let test_suite =
  Breath.Model.suite "Suite for Contract" [
    contract_can_be_originated
  ]

let () =
  Breath.Model.run_suites Void
  [
      test_suite
    ; Admin_Change_Fee.test_suite
    ; User_Deposits.test_suite
//  ; User_Redemptions.test_suite
//  ; Economics_Clearing.test_suite
  ]

