
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../common/helpers.mligo" "Helpers"
#import "../../batcher.mligo" "Batcher"


let add_liquidity_should_succeed =
  Breath.Model.case
  "test add liquidity"
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
      let prior_balances = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let act_allow_transfer =   Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to context.contracts.tzbtc (Approve allowance) 0tez)) in
      let act_add_liquidity = Helpers.add_liquidity btc_trader batcher token_name deposit_amount bstorage.valid_tokens in

      let bstorage = Breath.Contract.storage_of batcher in
      
      let market_maker = bstorage.market_maker in
      let h_key: Batcher.user_holding_key = (btc_trader.address, token_name) in
      let vault = Option.unopt (Big_map.find_opt token_name market_maker.vaults) in
      let user_holding = Option.unopt (Big_map.find_opt h_key market_maker.user_holdings) in
      let vault_holding = Option.unopt (Big_map.find_opt user_holding market_maker.vault_holdings) in
      let is_mem = Set.mem user_holding vault.holdings in
      let post_balances = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let expected_prior_balance = 90000000000n in
      let expected_post_balance = abs (expected_prior_balance - deposit_amount) in

      Breath.Result.reduce [
        act_allow_transfer
        ; act_add_liquidity
        ; Breath.Assert.is_equal "total shares should be same" deposit_amount vault.total_shares
        ; Breath.Assert.is_equal "vault should have the holding" is_mem true
        ; Breath.Assert.is_equal "holder should be the one that supplied liquidity" btc_trader.address vault_holding.holder
        ; Breath.Assert.is_equal "for the first liquidity , total shares hould be equal to holding shares" vault_holding.shares vault.total_shares
        ; Breath.Assert.is_equal "for the first liquidity , shares should be equal to amount" vault.native_token.amount vault.total_shares
        ; Breath.Assert.is_equal "for the first liquidity , shares should be equal to deposit amount" deposit_amount vault.total_shares
        ; Breath.Assert.is_equal "tzbtc balance prior" prior_balances.tzbtc expected_prior_balance
        ; Breath.Assert.is_equal "tzbtc balance post" post_balances.tzbtc expected_post_balance
      ])

let update_liquidity_for_same_user_should_succeed =
  Breath.Model.case
  "test update liquidity"
  "for same user should increase shares "
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
      let act_allow_transfer =   Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to context.contracts.tzbtc (Approve allowance) 0tez)) in
      let act_add_liquidity = Helpers.add_liquidity btc_trader batcher token_name deposit_amount bstorage.valid_tokens in

      let bstorage = Breath.Contract.storage_of batcher in
      
      let first_market_maker = bstorage.market_maker in
      let h_key: Batcher.user_holding_key = (btc_trader.address, token_name) in
      let first_vault = Option.unopt (Big_map.find_opt token_name first_market_maker.vaults) in
      let first_user_holding = Option.unopt (Big_map.find_opt h_key first_market_maker.user_holdings) in
      let first_vault_holding = Option.unopt (Big_map.find_opt first_user_holding first_market_maker.vault_holdings) in

      let prior_balances = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let act_allow_second_transfer =   Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to context.contracts.tzbtc (Approve allowance) 0tez)) in
      let act_add_additional_liquidity = Helpers.add_liquidity btc_trader batcher token_name deposit_amount bstorage.valid_tokens in

      let ustorage = Breath.Contract.storage_of batcher in
      
      let twice_deposit_amount = abs (2 * deposit_amount) in
      let second_market_maker = ustorage.market_maker in
      let second_vault = Option.unopt (Big_map.find_opt token_name second_market_maker.vaults) in
      let second_user_holding = Option.unopt (Big_map.find_opt h_key second_market_maker.user_holdings) in
      let second_vault_holding = Option.unopt (Big_map.find_opt second_user_holding second_market_maker.vault_holdings) in

      let post_balances = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let expected_prior_balance = abs (90000000000n - deposit_amount) in
      let expected_post_balance = abs (expected_prior_balance - deposit_amount) in
      Breath.Result.reduce [
        act_allow_transfer
        ; act_add_liquidity
        ; Breath.Assert.is_equal "total shares should be same" deposit_amount first_vault.total_shares
        ; Breath.Assert.is_equal "holder should be the one that supplied liquidity" btc_trader.address first_vault_holding.holder
        ; Breath.Assert.is_equal "for the first liquidity , total shares hould be equal to holding shares" first_vault_holding.shares first_vault.total_shares
        ; Breath.Assert.is_equal "for the first liquidity , shares should be equal to amount" first_vault.native_token.amount first_vault.total_shares
        ; Breath.Assert.is_equal "for the first liquidity , shares should be equal to deposit amount" deposit_amount first_vault.total_shares
        ; act_allow_second_transfer
        ; act_add_additional_liquidity
        ; Breath.Assert.is_equal "total shares should be twice the deposit amount" twice_deposit_amount second_vault.total_shares
        ; Breath.Assert.is_equal "holder should be the one that supplied liquidity" btc_trader.address second_vault_holding.holder
        ; Breath.Assert.is_equal "for the second liquidity , total shares hould be equal to holding shares" second_vault_holding.shares second_vault.total_shares
        ; Breath.Assert.is_equal "for the second liquidity , shares should be equal to amount" second_vault.native_token.amount second_vault.total_shares
        ; Breath.Assert.is_equal "for the second liquidity , shares should be equal to deposit amount" twice_deposit_amount second_vault.total_shares
        ; Breath.Assert.is_equal "tzbtc balance prior" prior_balances.tzbtc expected_prior_balance
        ; Breath.Assert.is_equal "tzbtc balance post" post_balances.tzbtc expected_post_balance
      ])

let add_liquidity_for_two_users_should_succeed =
  Breath.Model.case
  "test add liquidity"
  "for two users should suceed "
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let btc_trader = context.btc_trader in 
      let usdt_trader = context.usdt_trader in 

      let bstorage = Breath.Contract.storage_of batcher in

       let token_name = "tzBTC" in

      let deposit_amount = 2000000n in
      let allowance = {
        spender = batcher.originated_address;
        value = deposit_amount
       } in
      let prior_balances_tzbtc = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let prior_balances_usdt = Helpers.get_balances usdt_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let act_allow_transfer_trader_1 =   Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to context.contracts.tzbtc (Approve allowance) 0tez)) in
      let act_add_liquidity_trader_1 = Helpers.add_liquidity btc_trader batcher token_name deposit_amount bstorage.valid_tokens in
      let act_allow_transfer_trader_2 =   Breath.Context.act_as usdt_trader (fun (_u:unit) -> (Breath.Contract.transfer_to context.contracts.tzbtc (Approve allowance) 0tez)) in
      let act_add_liquidity_trader_2 = Helpers.add_liquidity usdt_trader batcher token_name deposit_amount bstorage.valid_tokens in

      let bstorage = Breath.Contract.storage_of batcher in
      let market_maker = bstorage.market_maker in
      let h_key_1: Batcher.user_holding_key = (btc_trader.address, token_name) in
      let h_key_2: Batcher.user_holding_key = (usdt_trader.address, token_name) in
      let vault = Option.unopt (Big_map.find_opt token_name market_maker.vaults) in
      let user_holding_1 = Option.unopt (Big_map.find_opt h_key_1 market_maker.user_holdings) in
      let vault_holding_1 = Option.unopt (Big_map.find_opt user_holding_1 market_maker.vault_holdings) in
      let user_holding_2 = Option.unopt (Big_map.find_opt h_key_2 market_maker.user_holdings) in
      let vault_holding_2 = Option.unopt (Big_map.find_opt user_holding_2 market_maker.vault_holdings) in

      let total_shares = abs (2 * deposit_amount) in

      let post_balances_tzbtc = Helpers.get_balances btc_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
      let post_balances_usdt = Helpers.get_balances usdt_trader.address context.contracts.tzbtc context.contracts.usdt context.contracts.eurl in 
       let tzbtc_bal_diff = abs (prior_balances_tzbtc.tzbtc - post_balances_tzbtc.tzbtc) in
       let usdt_bal_diff = abs (prior_balances_usdt.tzbtc - post_balances_usdt.tzbtc) in


      Breath.Result.reduce [
        act_allow_transfer_trader_1
        ; act_add_liquidity_trader_1
        ; act_allow_transfer_trader_2
        ; act_add_liquidity_trader_2
        ; Breath.Assert.is_equal "total shares should be same" total_shares vault.total_shares
        ; Breath.Assert.is_equal "holder should be the one that supplied liquidity (trader_1)" btc_trader.address vault_holding_1.holder
        ; Breath.Assert.is_equal "holder should be the one that supplied liquidity (trader_2)" usdt_trader.address vault_holding_2.holder
        ; Breath.Assert.is_equal "holding shares (trader_1) should be equal deposit amount" vault_holding_1.shares deposit_amount
        ; Breath.Assert.is_equal "holding shares (trader_2) should be equal deposit amount" vault_holding_2.shares deposit_amount
        ; Breath.Assert.is_equal "for the first liquidity , shares should be equal to amount" vault.native_token.amount vault.total_shares
        ; Breath.Assert.is_equal "shares should be equal to both deposit amounts" total_shares vault.total_shares
        ; Breath.Assert.is_equal "tzbtc balance difference should be deposit" tzbtc_bal_diff deposit_amount
        ; Breath.Assert.is_equal "tzbtc (trader 2) balance difference should be deposit" usdt_bal_diff deposit_amount
      ])

let test_suite =
  Breath.Model.suite "Suite for Add / Update Liquidity" [
    add_liquidity_should_succeed
    ; update_liquidity_for_same_user_should_succeed
    ; add_liquidity_for_two_users_should_succeed
  ]

