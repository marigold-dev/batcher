
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../common/helpers.mligo" "Helpers"
#import "../../batcher.mligo" "Batcher"


let remove_liquidity_should_succeed =
  Breath.Model.case
  "test remove liquidity"
  "should be successful"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let btc_trader = context.btc_trader in 

      let bstorage = Breath.Contract.storage_of batcher in

       let token_name = "tzBTC" in

      let deposit_amount = 2000000n in
      let allowance = {
        spender = batcher.originated_address;
        value = deposit_amount
       } in
      let initial_balances = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let act_allow_transfer =   Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to context.contracts.tzbtc (Approve allowance) 0tez)) in
      let act_add_liquidity = Helpers.add_liquidity btc_trader batcher token_name deposit_amount bstorage.valid_tokens in

      let after_addition_balances = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let bstorage = Breath.Contract.storage_of batcher in
      
      let market_maker = bstorage.market_maker in
      let h_key: Batcher.user_holding_key = (btc_trader.address, token_name) in
      let vault = Option.unopt (Big_map.find_opt token_name market_maker.vaults) in
      let user_holding = Option.unopt (Big_map.find_opt h_key market_maker.user_holdings) in
      let vault_holding = Option.unopt (Big_map.find_opt user_holding market_maker.vault_holdings) in

      let act_remove_liquidity = Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (RemoveLiquidity token_name) 0tez)) in

      let after_removal_balances = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let after_bstorage = Breath.Contract.storage_of batcher in
      
      let after_market_maker = after_bstorage.market_maker in
      let after_vault = Option.unopt (Big_map.find_opt token_name after_market_maker.vaults) in
      let after_user_holding = Big_map.find_opt h_key after_market_maker.user_holdings in


      let expected_initial_balance = 90000000000n in
      let expected_balance_after_addition = abs (expected_initial_balance - deposit_amount) in

      Breath.Result.reduce [
        act_allow_transfer
        ; act_add_liquidity
        ; Breath.Assert.is_equal "total shares should be same" deposit_amount vault.total_shares
        ; Breath.Assert.is_equal "holder should be the one that supplied liquidity" btc_trader.address vault_holding.holder
        ; Breath.Assert.is_equal "for the first liquidity , total shares should be equal to holding shares" vault_holding.shares vault.total_shares
        ; Breath.Assert.is_equal "for the first liquidity , shares should be equal to amount" vault.native_token.amount vault.total_shares
        ; Breath.Assert.is_equal "for the first liquidity , shares should be equal to deposit amount" deposit_amount vault.total_shares
        ; act_remove_liquidity
        ; Breath.Assert.is_equal "after removal, total shares should be 0" 0n after_vault.total_shares
        ; Breath.Assert.is_equal "after removal, native token amount should be 0" 0n after_vault.native_token.amount
        ; Breath.Assert.is_none "after removal, user should have no holdings" after_user_holding
        ; Breath.Assert.is_equal "initial tzbtc balance" initial_balances.tzbtc expected_initial_balance
        ; Breath.Assert.is_equal "tzbtc balance after addition should be less by the deposit amount" after_addition_balances.tzbtc expected_balance_after_addition
        ; Breath.Assert.is_equal "tzbtc balance after removal should be back to initial balance" after_removal_balances.tzbtc expected_initial_balance
      ])

let test_suite =
  Breath.Model.suite "Suite for Remove Liquidity" [
    remove_liquidity_should_succeed
  ]

