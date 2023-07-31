#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./common/helpers.mligo" "Helpers"
#import "./endpoints/user/test_deposits.mligo" "User_Deposits"
#import "./endpoints/user/test_redemptions.mligo" "User_Redemptions"
#import "./economics/test_clearing.mligo" "Economics_Clearing"
#import "./endpoints/admin/test_change_fee.mligo" "Admin_Change_Fee"
#import "./endpoints/admin/test_change_admin_address.mligo" "Admin_Change_Admin_Address"
#import "./endpoints/admin/test_change_fee_recipient_address.mligo" "Admin_Change_Fee_Recipient_Address"
#import "./endpoints/admin/test_change_deposit_time_window.mligo" "Admin_Change_Deposit_Time_Window"
#import "./endpoints/admin/test_enable_disable_swap_pair_for_deposit.mligo" "Admin_Enable_Disable_Swap_Pair"
#import "./endpoints/admin/test_add_update_remove_metadata.mligo" "Admin_Add_Update_Remove_Metadata"
#import "./endpoints/admin/test_amend_token_pair_limit.mligo" "Admin_Amend_Token_pair_Limit"
#import "./endpoints/admin/test_change_oracle_source_of_pair.mligo" "Admin_Change_Oracle_Source_Of_Pair"
#import "./endpoints/admin/test_add_remove_token_swap_pair.mligo" "Admin_Add_Remove_Token_Swap_Pair"
#import "./endpoints/maintenance/test_tick.mligo" "Maintenance_Tick"
#import "./economics/test_clearing.mligo" "Economics_Clearing"


let contract_can_be_originated =
  Breath.Model.case
  "test contract"
  "can be originated"
    (fun (level: Breath.Logger.level) ->
      let () = Breath.Logger.log level "Originate Batcher contract" in
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in
      let contracts = Helpers.originate level btc_trader usdt_trader eurl_trader in
      let batcher_storage = Breath.Contract.storage_of contracts.batcher in
      let batcher_balance = Breath.Contract.balance_of contracts.batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "balance" batcher_balance 0tez
      ; Helpers.expect_last_order_number batcher_storage 0n
      ])


let test_suite =
  Breath.Model.suite "Suite for Contract" [
    contract_can_be_originated
  ]

let () =
  Breath.Model.run_suites Void
  [
      test_suite
    ; Admin_Change_Fee.test_suite
    ; Admin_Change_Admin_Address.test_suite
    ; Admin_Change_Fee_Recipient_Address.test_suite
    ; Admin_Change_Deposit_Time_Window.test_suite
    ; Admin_Enable_Disable_Swap_Pair.test_suite
    ; Admin_Amend_Token_pair_Limit.test_suite
    ; Admin_Add_Update_Remove_Metadata.test_suite
    ; Admin_Change_Oracle_Source_Of_Pair.test_suite
    ; Admin_Add_Remove_Token_Swap_Pair.test_suite
    ; Maintenance_Tick.test_suite
    ; Economics_Clearing.test_suite
    ; User_Deposits.test_suite
//  ; User_Redemptions.test_suite
//  ; Economics_Clearing.test_suite
  ]

