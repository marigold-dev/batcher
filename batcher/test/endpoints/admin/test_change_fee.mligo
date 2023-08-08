
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../common/helpers.mligo" "Helpers"
#import "../../../batcher.mligo" "Batcher"


let change_fee_should_succeed_if_user_is_admin =
  Breath.Model.case
  "test change fee"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let old_fee = old_storage.fee_in_mutez in
      let new_fee = 20000mutez in
      let act_change_fee = Breath.Context.act_as context.eurl_trader (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_fee new_fee) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old fee" old_fee old_storage.fee_in_mutez
        ; act_change_fee
        ; Breath.Assert.is_equal "new fee" new_fee new_storage.fee_in_mutez
      ])

let change_fee_should_fail_if_user_is_not_admin =
  Breath.Model.case
  "test change fee"
  "should fail if user is not admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in

      let old_fee = old_storage.fee_in_mutez in
      let new_fee = 20000mutez in
     
      let act_change_fee = Breath.Context.act_as context.btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_fee new_fee) 0tez)) in

      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old fee" old_fee old_storage.fee_in_mutez
        ; Breath.Expect.fail_with_value Batcher.sender_not_administrator act_change_fee
        ; Breath.Assert.is_equal "old fee is unchanged" old_fee new_storage.fee_in_mutez
      ])

let change_fee_should_fail_if_tez_is_sent =
  Breath.Model.case
  "test change fee"
  "should fail if tez is sent"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let old_fee = old_storage.fee_in_mutez in
      let new_fee = 20000mutez in
      let act_change_fee = Breath.Context.act_as context.eurl_trader (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_fee new_fee) 5tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old fee" old_fee old_storage.fee_in_mutez
        ; Breath.Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_change_fee
        ; Breath.Assert.is_equal "old fee is unchanged" old_fee new_storage.fee_in_mutez
      ])
let test_suite =
  Breath.Model.suite "Suite for Change Fee (Admin)" [
    change_fee_should_succeed_if_user_is_admin
    ; change_fee_should_fail_if_user_is_not_admin
    ; change_fee_should_fail_if_tez_is_sent
  ]

