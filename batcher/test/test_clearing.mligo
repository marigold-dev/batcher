#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./common/utils.mligo" "Utils"


let clearing_placeholder =
  Breath.Model.case
  "test clearing"
  "placeholder"
    (fun (level: Breath.Logger.level) ->
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in

      Breath.Result.reduce [
        Breath.Assert.is_equal "placeholder" 0n 0n
      ])


let test_suite =
  Breath.Model.suite "Suite for Clearing" [
     clearing_placeholder
  ]


