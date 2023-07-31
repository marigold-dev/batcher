#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../common/helpers.mligo" "Helpers"
#import "./../../common/expect.mligo" "Expect"
#import "../../../batcher.mligo" "Batcher"

let get_tzbtc_eurl_swap_pair
  (disabled: bool)
  (oracle: address)
  (storage: Batcher.Storage.t): (Batcher.valid_swap * Batcher.valid_swap_reduced) = 
  let valid_tokens = storage.valid_tokens in
  let tzbtc = Option.unopt (Map.find_opt "tzBTC" valid_tokens) in
  let eurl = Option.unopt (Map.find_opt "EURL" valid_tokens) in
  let swap : Batcher.swap = {
      from = {
        token = tzbtc;
        amount = 1n;
      };
      to = eurl;
  } in
  let swap_reduced : Batcher.swap_reduced = {
      to = eurl.name;
      from = tzbtc.name;
  } in
  let valid_swap: Batcher.valid_swap = 
  {
    swap = swap;
    oracle_address = oracle;
    oracle_asset_name = "BTC-EURL";
    oracle_precision = 6n;
    is_disabled_for_deposits = disabled;
  } in
  let valid_swap_reduced =
  {
    swap = swap_reduced;
    oracle_address = oracle;
    oracle_asset_name = "BTC-EURL";
    oracle_precision = 6n;
    is_disabled_for_deposits = disabled;
  } in
  (valid_swap, valid_swap_reduced)

let add_swap_pair_should_succeed_if_user_is_admin =
  Breath.Model.case
  "test add swap pair"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let bstorage = Breath.Contract.storage_of batcher in
      let swap_pair_does_not_already_exist = Map.find_opt "tzBTC/EURL" bstorage.valid_swaps in
      let (swap_pair, swap_pair_reduced) = get_tzbtc_eurl_swap_pair true context.contracts.oracle.originated_address bstorage in
      let act_add_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_token_swap_pair swap_pair) 0tez)) in
      
      let new_bstorage = Breath.Contract.storage_of batcher in
      let added_swap_pair_reduced = Option.unopt (Map.find_opt "tzBTC/EURL" new_bstorage.valid_swaps) in

      Breath.Result.reduce [
        Breath.Assert.is_equal "swap pair should not already exist" None swap_pair_does_not_already_exist 
        ; act_add_swap_pair
        ; Breath.Assert.is_equal "swap pair should have been added" swap_pair_reduced added_swap_pair_reduced
      ])

let add_swap_pair_should_fail_if_user_is_non_admin =
  Breath.Model.case
  "test add swap pair"
  "should be fail if user is non admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let bstorage = Breath.Contract.storage_of batcher in
      let swap_pair_does_not_already_exist = Map.find_opt "tzBTC/EURL" bstorage.valid_swaps in
      let (swap_pair, _) = get_tzbtc_eurl_swap_pair true context.contracts.oracle.originated_address bstorage in
      let act_add_swap_pair = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_token_swap_pair swap_pair) 0tez)) in
      
      let new_bstorage = Breath.Contract.storage_of batcher in
      let added_swap_pair_reduced = Map.find_opt "tzBTC/EURL" new_bstorage.valid_swaps in

      Breath.Result.reduce [
        Breath.Assert.is_equal "swap pair should not already exist" None swap_pair_does_not_already_exist 
        ; Expect.fail_with_value Batcher.sender_not_administrator act_add_swap_pair
        ; Breath.Assert.is_equal "swap pair still does not exist" None added_swap_pair_reduced
      ])

let add_swap_pair_should_fail_if_tez_is_supplied =
  Breath.Model.case
  "test add swap pair"
  "should be fail if tez is supplied"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let bstorage = Breath.Contract.storage_of batcher in
      let swap_pair_does_not_already_exist = Map.find_opt "tzBTC/EURL" bstorage.valid_swaps in
      let (swap_pair, _) = get_tzbtc_eurl_swap_pair true context.contracts.oracle.originated_address bstorage in
      let act_add_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_token_swap_pair swap_pair) 5tez)) in
      
      let new_bstorage = Breath.Contract.storage_of batcher in
      let added_swap_pair_reduced = Map.find_opt "tzBTC/EURL" new_bstorage.valid_swaps in

      Breath.Result.reduce [
        Breath.Assert.is_equal "swap pair should not already exist" None swap_pair_does_not_already_exist 
        ; Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_add_swap_pair
        ; Breath.Assert.is_equal "swap pair still does not exist" None added_swap_pair_reduced
      ])

let remove_swap_pair_should_succeed_if_user_is_admin =
  Breath.Model.case
  "test remove swap pair"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let bstorage = Breath.Contract.storage_of batcher in
      let swap_pair_does_not_already_exist = Map.find_opt "tzBTC/EURL" bstorage.valid_swaps in
      let (swap_pair, swap_pair_reduced) = get_tzbtc_eurl_swap_pair true context.contracts.oracle.originated_address bstorage in
      let act_add_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_token_swap_pair swap_pair) 0tez)) in
      
      let new_bstorage = Breath.Contract.storage_of batcher in
      let added_swap_pair_reduced = Option.unopt (Map.find_opt "tzBTC/EURL" new_bstorage.valid_swaps) in

      let act_remove_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Remove_token_swap_pair swap_pair) 0tez)) in
      
      let r_storage = Breath.Contract.storage_of batcher in
      let removed_swap_pair_reduced = Map.find_opt "tzBTC/EURL" r_storage.valid_swaps in
      Breath.Result.reduce [
        Breath.Assert.is_equal "swap pair should not already exist" None swap_pair_does_not_already_exist 
        ; act_add_swap_pair
        ; Breath.Assert.is_equal "swap pair should have been added" swap_pair_reduced added_swap_pair_reduced
        ; act_remove_swap_pair
        ; Breath.Assert.is_equal "swap pair should have been removed" None removed_swap_pair_reduced
      ])

let remove_swap_pair_should_fail_if_user_is_non_admin =
  Breath.Model.case
  "test remove swap pair"
  "should be fail if user is non admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let bstorage = Breath.Contract.storage_of batcher in
      let swap_pair_does_not_already_exist = Map.find_opt "tzBTC/EURL" bstorage.valid_swaps in
      let (swap_pair, swap_pair_reduced) = get_tzbtc_eurl_swap_pair true context.contracts.oracle.originated_address bstorage in
      let act_add_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_token_swap_pair swap_pair) 0tez)) in
      
      let new_bstorage = Breath.Contract.storage_of batcher in
      let added_swap_pair_reduced = Option.unopt (Map.find_opt "tzBTC/EURL" new_bstorage.valid_swaps) in

      let act_remove_swap_pair = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Remove_token_swap_pair swap_pair) 0tez)) in
      
      let r_storage = Breath.Contract.storage_of batcher in
      let removed_swap_pair_reduced = Option.unopt (Map.find_opt "tzBTC/EURL" r_storage.valid_swaps) in

      Breath.Result.reduce [
        Breath.Assert.is_equal "swap pair should not already exist" None swap_pair_does_not_already_exist 
        ; act_add_swap_pair
        ; Breath.Assert.is_equal "swap pair should have been added" swap_pair_reduced added_swap_pair_reduced
        ; Expect.fail_with_value Batcher.sender_not_administrator act_remove_swap_pair
        ; Breath.Assert.is_equal "swap pair should still exist" swap_pair_reduced removed_swap_pair_reduced
      ])

let remove_swap_pair_should_fail_if_tez_is_supplied =
  Breath.Model.case
  "test remove swap pair"
  "should be fail if tez supplied"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let bstorage = Breath.Contract.storage_of batcher in
      let swap_pair_does_not_already_exist = Map.find_opt "tzBTC/EURL" bstorage.valid_swaps in
      let (swap_pair, swap_pair_reduced) = get_tzbtc_eurl_swap_pair true context.contracts.oracle.originated_address bstorage in
      let act_add_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_token_swap_pair swap_pair) 0tez)) in
      
      let new_bstorage = Breath.Contract.storage_of batcher in
      let added_swap_pair_reduced = Option.unopt (Map.find_opt "tzBTC/EURL" new_bstorage.valid_swaps) in

      let act_remove_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Remove_token_swap_pair swap_pair) 5tez)) in
      
      let r_storage = Breath.Contract.storage_of batcher in
      let removed_swap_pair_reduced = Option.unopt (Map.find_opt "tzBTC/EURL" r_storage.valid_swaps) in

      Breath.Result.reduce [
        Breath.Assert.is_equal "swap pair should not already exist" None swap_pair_does_not_already_exist 
        ; act_add_swap_pair
        ; Breath.Assert.is_equal "swap pair should have been added" swap_pair_reduced added_swap_pair_reduced
        ; Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_remove_swap_pair
        ; Breath.Assert.is_equal "swap pair should still exist" swap_pair_reduced removed_swap_pair_reduced
      ])

let remove_swap_pair_should_fail_if_swap_does_not_exist =
  Breath.Model.case
  "test remove swap pair"
  "should be fail if swap does not exist"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let bstorage = Breath.Contract.storage_of batcher in
      let swap_pair_does_not_already_exist = Map.find_opt "tzBTC/EURL" bstorage.valid_swaps in
      let (swap_pair, _swap_pair_reduced) = get_tzbtc_eurl_swap_pair true context.contracts.oracle.originated_address bstorage in

      let act_remove_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Remove_token_swap_pair swap_pair) 0tez)) in
      
      let r_storage = Breath.Contract.storage_of batcher in
      let removed_swap_pair_reduced = Map.find_opt "tzBTC/EURL" r_storage.valid_swaps in
      Breath.Result.reduce [
        Breath.Assert.is_equal "swap pair should not already exist" None swap_pair_does_not_already_exist 
        ; Expect.fail_with_value Batcher.swap_does_not_exist act_remove_swap_pair
        ; Breath.Assert.is_equal "swap pair should have been removed" None removed_swap_pair_reduced
      ])

let remove_swap_pair_should_fail_if_swap_is_not_disabled =
  Breath.Model.case
  "test remove swap pair"
  "should be fail if swap is not disabled"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let bstorage = Breath.Contract.storage_of batcher in
      let swap_pair_does_not_already_exist = Map.find_opt "tzBTC/EURL" bstorage.valid_swaps in
      let (swap_pair, _swap_pair_reduced) = get_tzbtc_eurl_swap_pair false context.contracts.oracle.originated_address bstorage in

      let act_remove_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Remove_token_swap_pair swap_pair) 0tez)) in
      
      let r_storage = Breath.Contract.storage_of batcher in
      let removed_swap_pair_reduced = Map.find_opt "tzBTC/EURL" r_storage.valid_swaps in
      Breath.Result.reduce [
        Breath.Assert.is_equal "swap pair should not already exist" None swap_pair_does_not_already_exist 
        ; Expect.fail_with_value Batcher.cannot_remove_swap_pair_that_is_not_disabled act_remove_swap_pair
        ; Breath.Assert.is_equal "swap pair should have been removed" None removed_swap_pair_reduced
      ])

let test_suite =
  Breath.Model.suite "Suite for Add/Remove Swap Pair (Admin)" [
    add_swap_pair_should_succeed_if_user_is_admin
    ; add_swap_pair_should_fail_if_user_is_non_admin
    ; add_swap_pair_should_fail_if_tez_is_supplied
    ; remove_swap_pair_should_succeed_if_user_is_admin
    ; remove_swap_pair_should_fail_if_swap_does_not_exist
    ; remove_swap_pair_should_fail_if_user_is_non_admin
    ; remove_swap_pair_should_fail_if_tez_is_supplied
    ; remove_swap_pair_should_fail_if_swap_is_not_disabled
  ]

