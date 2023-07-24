
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../common/helpers.mligo" "Helpers"
#import "./../../common/expect.mligo" "Expect"
#import "../../../batcher.mligo" "Batcher"


let change_deposit_time_window_should_succeed_if_user_is_admin =
  Breath.Model.case
  "test change deposit time window"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_window = 1200n in
      let act_change_deposit_time_window = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_deposit_time_window new_window) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "time window" 600n old_storage.deposit_time_window_in_seconds
        ; act_change_deposit_time_window
        ; Breath.Assert.is_equal "time window unchanged" new_window new_storage.deposit_time_window_in_seconds
      ])

let change_deposit_time_window_should_fail_if_user_is_not_admin =
  Breath.Model.case
  "test change deposit time window"
  "should be fail if user is not admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_window = 1200n in
      let act_change_deposit_time_window = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_deposit_time_window new_window) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "time window" 600n old_storage.deposit_time_window_in_seconds
        ; Expect.fail_with_value Batcher.sender_not_administrator act_change_deposit_time_window
        ; Breath.Assert.is_equal "time window unchanged" 600n new_storage.deposit_time_window_in_seconds
      ])

let change_deposit_time_window_should_fail_if_tez_is_sent =
  Breath.Model.case
  "test change deposit time window"
  "should fail if tez is sent"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_window = 1200n in
      let act_change_deposit_time_window = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_deposit_time_window new_window) 5tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "time window" 600n old_storage.deposit_time_window_in_seconds
        ; Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_change_deposit_time_window
        ; Breath.Assert.is_equal "time window unchanged" 600n new_storage.deposit_time_window_in_seconds
      ])

let change_deposit_time_window_should_fail_if_below_minimum_window =
  Breath.Model.case
  "test change deposit time window"
  "should fail if below minimum window"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_window = 500n in
      let act_change_deposit_time_window = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_deposit_time_window new_window) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "time window" 600n old_storage.deposit_time_window_in_seconds
        ; Expect.fail_with_value Batcher.cannot_update_deposit_window_to_less_than_the_minimum act_change_deposit_time_window
        ; Breath.Assert.is_equal "time window unchanged" 600n new_storage.deposit_time_window_in_seconds
      ])

let change_deposit_time_window_should_fail_if_above_maximum_window =
  Breath.Model.case
  "test change deposit time window"
  "should fail if above maximum window"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_window =4000n in
      let act_change_deposit_time_window = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Change_deposit_time_window new_window) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "time window" 600n old_storage.deposit_time_window_in_seconds
        ; Expect.fail_with_value Batcher.cannot_update_deposit_window_to_more_than_the_maximum act_change_deposit_time_window
        ; Breath.Assert.is_equal "time window unchanged" 600n new_storage.deposit_time_window_in_seconds
      ])

let test_suite =
  Breath.Model.suite "Suite for Change Admin Address (Admin)" [
    change_deposit_time_window_should_succeed_if_user_is_admin
    ; change_deposit_time_window_should_fail_if_user_is_not_admin
    ; change_deposit_time_window_should_fail_if_tez_is_sent
    ; change_deposit_time_window_should_fail_if_below_minimum_window
    ; change_deposit_time_window_should_fail_if_above_maximum_window
  ]

