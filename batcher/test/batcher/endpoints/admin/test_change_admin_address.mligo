
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../../common/helpers.mligo" "Helpers"
#import "../../../../batcher.mligo" "Batcher"


let change_admin_address_should_succeed_if_user_is_admin =
  Breath.Model.case
  "test change admin address"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_address = context.btc_trader.address in
      let act_change_admin_address = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_admin_address new_address) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old address" context.admin.address old_storage.administrator
        ; act_change_admin_address
        ; Breath.Assert.is_equal "new address" new_address new_storage.administrator
      ])

let change_admin_address_should_fail_if_user_is_not_admin =
  Breath.Model.case
  "test change admin address"
  "should fail if user is not admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_address = context.usdt_trader.address in
      let act_change_admin_address = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_admin_address new_address) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old address" context.admin.address old_storage.administrator
        ; Breath.Expect.fail_with_value Batcher.sender_not_administrator act_change_admin_address
        ; Breath.Assert.is_equal "address unchanged" context.admin.address new_storage.administrator
      ])

let change_admin_address_should_fail_if_tez_is_sent =
  Breath.Model.case
  "test change admin address"
  "should fail if tez is sent"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_address = context.usdt_trader.address in
      let act_change_admin_address = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_admin_address new_address) 5tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old address" context.admin.address old_storage.administrator
        ; Breath.Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_change_admin_address
        ; Breath.Assert.is_equal "address unchanged" context.admin.address new_storage.administrator
      ])

let change_admin_address_should_fail_if_new_address_is_the_same_as_fee_recipient =
  Breath.Model.case
  "test change admin address"
  "should fail if new address is the same as fee recipient"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_address = context.fee_recipient in
      let act_change_admin_address = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_admin_address new_address) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old address" context.admin.address old_storage.administrator
        ; Breath.Expect.fail_with_value Batcher.admin_and_fee_recipient_address_cannot_be_the_same act_change_admin_address
        ; Breath.Assert.is_equal "address unchanged" context.admin.address new_storage.administrator
      ])

let test_suite =
  Breath.Model.suite "Suite for Change Admin Address (Admin)" [
    change_admin_address_should_succeed_if_user_is_admin
    ; change_admin_address_should_fail_if_user_is_not_admin
    ; change_admin_address_should_fail_if_tez_is_sent
    ; change_admin_address_should_fail_if_new_address_is_the_same_as_fee_recipient
  ]

