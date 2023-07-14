#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./common/helpers.mligo" "Helpers"


let contract_can_be_originated =
  Breath.Model.case
  "test contract"
  "can be originated"
    (fun (level: Breath.Logger.level) ->
      let () = Breath.Logger.log level "Originate Batcher contract" in
      let contract = Helpers.originate level in
      let storage = Breath.Contract.storage_of contract in
      let balance = Breath.Contract.balance_of contract in

      Breath.Result.reduce [
        Breath.Assert.is_equal "balance" balance 0tez
      ; Helpers.expect_last_order_number storage 0n
      ])


let test_suite =
  Breath.Model.suite "Suite for Deposits" [
    contract_can_be_originated
  ]

