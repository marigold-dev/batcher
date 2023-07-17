#import "ligo-breathalyzer/lib/lib.mligo" "Breath"

#import "./test_contract.mligo" "Contract"
#import "./test_deposits.mligo" "Deposits"
#import "./test_redemptions.mligo" "Redemptions"
#import "./test_clearing.mligo" "Clearing"

let () =
  Breath.Model.run_suites Void
  [
      Contract.test_suite
//  ; Deposits.test_suite
//  ; Redemptions.test_suite
//  ; Clearing.test_suite
  ]

