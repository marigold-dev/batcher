#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../../common/helpers.mligo" "Helpers"
#import "../../../../batcher.mligo" "Batcher"
#import "../../../../errors.mligo" "Errors"

let pair = "tzBTC/USDT"
let oraclepair = "BTC-USDT"
let old_price = 30000000000n

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
      let (_,new_oracle_price): (timestamp * nat)  = Option.unopt (Tezos.call_view "getPrice" oraclepair new_oracle_address) in
      let act_change_oracle_source = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_oracle_source_of_pair source_update) 0tez)) in
      let new_test_swap = Option.unopt (Helpers.get_swap_pair batcher pair) in 

      Breath.Result.reduce [
        Breath.Assert.is_equal "new price" new_oracle_price old_price
        ; Breath.Assert.is_equal "old address" oracle.originated_address test_swap.oracle_address
        ; act_change_oracle_source
        ; Breath.Assert.is_equal "new address" new_oracle_address new_test_swap.oracle_address
      ])

let change_oracle_source_should_fail_if_the_user_is_non_admin =
  Breath.Model.case
  "test change oracle source"
  "should fail if the user is non admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let oracle = context.contracts.oracle in
      let additional_oracle = context.contracts.additional_oracle in
      let test_swap = Option.unopt (Helpers.get_swap_pair batcher pair) in 
      let new_oracle_address = additional_oracle.originated_address in
      let source_update = Helpers.get_source_update pair test_swap new_oracle_address in 
      let (_,new_oracle_price): (timestamp * nat)  = Option.unopt (Tezos.call_view "getPrice" oraclepair new_oracle_address) in
      let act_change_oracle_source = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_oracle_source_of_pair source_update) 0tez)) in
      let new_test_swap = Option.unopt (Helpers.get_swap_pair batcher pair) in 

      Breath.Result.reduce [
        Breath.Assert.is_equal "new price" new_oracle_price old_price
        ; Breath.Assert.is_equal "old address" oracle.originated_address test_swap.oracle_address
        ; Breath.Expect.fail_with_value Errors.sender_not_administrator act_change_oracle_source
        ; Breath.Assert.is_equal "old address unchanged" oracle.originated_address new_test_swap.oracle_address
      ])

let change_oracle_source_should_fail_if_tez_is_sent =
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
      let (_,new_oracle_price): (timestamp * nat)  = Option.unopt (Tezos.call_view "getPrice" oraclepair new_oracle_address) in
      let act_change_oracle_source = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_oracle_source_of_pair source_update) 5tez)) in
      let new_test_swap = Option.unopt (Helpers.get_swap_pair batcher pair) in 

      Breath.Result.reduce [
        Breath.Assert.is_equal "new price" new_oracle_price old_price
        ; Breath.Assert.is_equal "old address" oracle.originated_address test_swap.oracle_address
        ; Breath.Expect.fail_with_value Errors.endpoint_does_not_accept_tez act_change_oracle_source
        ; Breath.Assert.is_equal "old address unchanged" oracle.originated_address new_test_swap.oracle_address
      ])

let change_oracle_source_should_fail_if_not_a_valid_oracle =
  Breath.Model.case
  "test change oracle source"
  "should fail if not a valid oracle"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let oracle = context.contracts.oracle in
      let test_swap = Option.unopt (Helpers.get_swap_pair batcher pair) in 
      let new_oracle_address = context.btc_trader.address in
      let source_update = Helpers.get_source_update pair test_swap new_oracle_address in 
      let act_change_oracle_source = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_oracle_source_of_pair source_update) 0tez)) in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old address" oracle.originated_address test_swap.oracle_address
        ; act_change_oracle_source
        ; Breath.Assert.is_equal "old address unchanged " oracle.originated_address test_swap.oracle_address
      ])

let test_suite =
  Breath.Model.suite "Suite for Change Oracle Address (Admin)" [
    change_oracle_source_should_succeed_if_user_is_admin
    ; change_oracle_source_should_fail_if_the_user_is_non_admin
    ; change_oracle_source_should_fail_if_tez_is_sent
    ; change_oracle_source_should_fail_if_not_a_valid_oracle
  ]

