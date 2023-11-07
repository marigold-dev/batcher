
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./common/helpers.mligo" "Helpers"
#import "./tokenmanager/endpoints/admin/test_change_admin_address.mligo" "Admin_Change_Admin_Address"
#import "./tokenmanager/endpoints/admin/test_change_marketmaker_address.mligo" "Admin_Change_MarketMaker_Address"
#import "./tokenmanager/endpoints/admin/test_enable_disable_swap_pair_for_deposit.mligo" "Admin_Enable_Disable_Swap_Pair"
#import "./tokenmanager/endpoints/admin/test_amend_token_pair_limit.mligo" "Admin_Amend_Token_pair_Limit"
#import "./tokenmanager/endpoints/admin/test_change_oracle_source_of_pair.mligo" "Admin_Change_Oracle_Source_Of_Pair"
#import "./tokenmanager/endpoints/admin/test_add_remove_token_swap_pair.mligo" "Admin_Add_Remove_Token_Swap_Pair"

let contract_can_be_originated =
  Breath.Model.case
  "test contract"
  "can be originated"
    (fun (level: Breath.Logger.level) ->
      let () = Breath.Logger.log level "Originate Token Manager contract" in
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in
      let (tm,oracle,additional_oracle,tzbtc,usdt,eurl) = Helpers.originate_tm level btc_trader usdt_trader eurl_trader btc_trader in
      let tm_storage = Breath.Contract.storage_of contracts.tokenmanager in
      let tm_balance = Breath.Contract.balance_of contracts.tokenmanager in

      Breath.Result.reduce [
        Breath.Assert.is_equal "balance" tm_balance 0tez
      ; Helpers.expect_last_order_number tm_storage 0n
      ])


let test_suite =
  Breath.Model.suite "Suite for Contract" [
    contract_can_be_originated
  ]

let () =
  Breath.Model.run_suites Void
  [
      test_suite
    (*  ; Admin_Change_Admin_Address.test_suite *)
    ; Admin_Change_MarketMaker_Address.test_suite
    ; Admin_Enable_Disable_Swap_Pair.test_suite
    ; Admin_Amend_Token_pair_Limit.test_suite
    ; Admin_Change_Oracle_Source_Of_Pair.test_suite
    ; Admin_Add_Remove_Token_Swap_Pair.test_suite *)
  ]

