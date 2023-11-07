#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../../common/helpers.mligo" "Helpers"
#import "../../../../batcher.mligo" "Batcher"
#import "../../../../errors.mligo" "Errors"


let amend_token_pair_limit_should_succeed_if_user_is_admin =
  Breath.Model.case
  "test change token pair limit"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_limit = 20n in 
      let act_amend_token_pair_limit = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher ( Amend_token_and_pair_limit new_limit) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old limit" 10n old_storage.limit_on_tokens_or_pairs
        ; act_amend_token_pair_limit
        ; Breath.Assert.is_equal "new limit" new_limit new_storage.limit_on_tokens_or_pairs
      ])

let amend_token_pair_limit_should_fail_if_user_is_not_admin =
  Breath.Model.case
  "test change token pair limit"
  "should fail if user is not an admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_limit = 20n in 
      let act_amend_token_pair_limit = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher ( Amend_token_and_pair_limit new_limit) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old limit" 10n old_storage.limit_on_tokens_or_pairs
        ; Breath.Expect.fail_with_value Errors.sender_not_administrator act_amend_token_pair_limit
        ; Breath.Assert.is_equal "limit unchanged" 10n new_storage.limit_on_tokens_or_pairs
      ])

let amend_token_pair_limit_should_fail_if_tez_is_sent =
  Breath.Model.case
  "test change token pair limit"
  "should fail if tez is sent"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_limit = 20n in 
      let act_amend_token_pair_limit = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher ( Amend_token_and_pair_limit new_limit) 5tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old limit" 10n old_storage.limit_on_tokens_or_pairs
        ; Breath.Expect.fail_with_value Errors.endpoint_does_not_accept_tez act_amend_token_pair_limit
        ; Breath.Assert.is_equal "limit unchanged" 10n new_storage.limit_on_tokens_or_pairs
      ])

let amend_token_pair_limit_should_fail_if_limit_is_less_than_current_tokens =
  Breath.Model.case
  "test change token pair limit"
  "should fail if limit is less than current tokens"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in
      let new_limit = 1n in 
      let act_amend_token_pair_limit = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher ( Amend_token_and_pair_limit new_limit) 0tez)) in
      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old limit" 10n old_storage.limit_on_tokens_or_pairs
        ; Breath.Expect.fail_with_value Errors.cannot_reduce_limit_on_tokens_to_less_than_already_exists act_amend_token_pair_limit
        ; Breath.Assert.is_equal "limit unchanged" 10n new_storage.limit_on_tokens_or_pairs
      ])

let test_suite =
  Breath.Model.suite "Suite for Change Admin Address (Admin)" [
    amend_token_pair_limit_should_succeed_if_user_is_admin
    ; amend_token_pair_limit_should_fail_if_user_is_not_admin
    ; amend_token_pair_limit_should_fail_if_tez_is_sent
    ; amend_token_pair_limit_should_fail_if_limit_is_less_than_current_tokens
  ]

