#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../common/helpers.mligo" "Helpers"
#import "./../../common/expect.mligo" "Expect"
#import "../../../batcher.mligo" "Batcher"

let pair = "tzBTC/USDT"

let change_oracle_source_should_succeed_if_user_is_admin =
  Breath.Model.case
  "test change oracle source"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let oracle = context.contracts.oracle in
      let additional_oracle = context.contracts.additional_oracle in
      let test_swap = Option.unopt (Helpers.get_swap_pair batcher pair) in 
      let new_oracle_address = additional_oracle.originated_address in
      let source_update = Helpers.get_source_update pair test_swap new_oracle_address in 

      let act_change_oracle_source = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_oracle_source_of_pair source_update) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in
      let new_test_swap = Option.unopt (Helpers.get_swap_pair batcher pair) in 

      Breath.Result.reduce [
        Breath.Assert.is_equal "old address" oracle.originated_address test_swap.oracle_address
       // ; act_change_oracle_source
        //; Breath.Assert.is_equal "new address" new_oracle_address new_test_swap.oracle_address
      ])


let test_suite =
  Breath.Model.suite "Suite for Change Oracle Address (Admin)" [
    change_oracle_source_should_succeed_if_user_is_admin
  ]

