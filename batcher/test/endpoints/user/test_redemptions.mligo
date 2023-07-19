#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../common/utils.mligo" "Utils"


let vanilla_redemption =
  Breath.Model.case
  "test redemption"
  "should be successful"
    (fun (_level: Breath.Logger.level) ->

      Breath.Result.reduce [
        Breath.Assert.is_equal "placeholder" 0n 0n
      ])


let test_suite =
  Breath.Model.suite "Suite for Redemptions" [
    vanilla_redemption
  ]

