
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../../common/helpers.mligo" "Helpers"
#import "../../../../batcher.mligo" "Batcher"

let pair = "tzBTC/USDT"
let oraclepair = "BTC-USDT"

let tick_should_succeed_if_oracle_price_is_available_and_not_stale =
  Breath.Model.case
  "test tick"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let act_tick = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Tick pair) 0tez)) in

      Breath.Result.reduce [
        act_tick
      ])


let test_suite =
  Breath.Model.suite "Suite for Tick (Maintenance)" [
    tick_should_succeed_if_oracle_price_is_available_and_not_stale
  ]

