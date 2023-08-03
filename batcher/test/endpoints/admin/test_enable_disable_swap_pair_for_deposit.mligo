
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../common/helpers.mligo" "Helpers"
#import "../../../batcher.mligo" "Batcher"


let enable_disable_swap_pair_should_succeed_if_user_is_admin =
  Breath.Model.case
  "test enable disable swap pair"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let pair = "tzBTC/USDT" in 
      let initial_pair = Option.unopt (Helpers.get_swap_pair batcher pair) in
      let act_disable_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Disable_swap_pair_for_deposit pair) 0tez)) in
      let disabled_pair = Option.unopt (Helpers.get_swap_pair batcher pair) in
      let act_enable_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Enable_swap_pair_for_deposit pair) 0tez)) in
      let enabled_pair = Option.unopt (Helpers.get_swap_pair batcher pair) in

      Breath.Result.reduce [
        Breath.Assert.is_equal "pair should be enabled" false initial_pair.is_disabled_for_deposits
        ; act_disable_swap_pair
        ; Breath.Assert.is_equal "pair should be disabled" true disabled_pair.is_disabled_for_deposits
        ; act_enable_swap_pair
        ; Breath.Assert.is_equal "pair should be enabled" false enabled_pair.is_disabled_for_deposits
      ])

let enable_disable_swap_pair_should_fail_if_user_is_not_admin =
  Breath.Model.case
  "test enable disable swap pair"
  "should fail if user is not admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let pair = "tzBTC/USDT" in 
      let initial_pair = Option.unopt (Helpers.get_swap_pair batcher pair) in
      let act_disable_swap_pair = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Disable_swap_pair_for_deposit pair) 0tez)) in
      let disabled_pair = Option.unopt (Helpers.get_swap_pair batcher pair) in
      let act_enable_swap_pair = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Enable_swap_pair_for_deposit pair) 0tez)) in
      let enabled_pair = Option.unopt (Helpers.get_swap_pair batcher pair) in

      Breath.Result.reduce [
        Breath.Assert.is_equal "pair should be enabled" false initial_pair.is_disabled_for_deposits
        ; Breath.Expect.fail_with_value Batcher.sender_not_administrator act_disable_swap_pair
        ; Breath.Assert.is_equal "pair should still be enabled" false disabled_pair.is_disabled_for_deposits
        ; Breath.Expect.fail_with_value Batcher.sender_not_administrator act_enable_swap_pair
        ; Breath.Assert.is_equal "pair should still be enabled" false enabled_pair.is_disabled_for_deposits
      ])

let enable_disable_swap_pair_should_fail_if_tez_is_supplied =
  Breath.Model.case
  "test enable disable swap pair"
  "should fail if tez is supplied"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let pair = "tzBTC/USDT" in 
      let initial_pair = Option.unopt (Helpers.get_swap_pair batcher pair) in
      let act_disable_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Disable_swap_pair_for_deposit pair) 5tez)) in
      let disabled_pair = Option.unopt (Helpers.get_swap_pair batcher pair) in
      let act_enable_swap_pair = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Enable_swap_pair_for_deposit pair) 5tez)) in
      let enabled_pair = Option.unopt (Helpers.get_swap_pair batcher pair) in

      Breath.Result.reduce [
        Breath.Assert.is_equal "pair should be enabled" false initial_pair.is_disabled_for_deposits
        ; Breath.Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_disable_swap_pair
        ; Breath.Assert.is_equal "pair should still be enabled" false disabled_pair.is_disabled_for_deposits
        ; Breath.Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_enable_swap_pair
        ; Breath.Assert.is_equal "pair should still be enabled" false enabled_pair.is_disabled_for_deposits
      ])

let test_suite =
  Breath.Model.suite "Suite for Enable/Disable Swap Pairs (Admin)" [
    enable_disable_swap_pair_should_succeed_if_user_is_admin
    ; enable_disable_swap_pair_should_fail_if_user_is_not_admin
    ; enable_disable_swap_pair_should_fail_if_tez_is_supplied
  ]

