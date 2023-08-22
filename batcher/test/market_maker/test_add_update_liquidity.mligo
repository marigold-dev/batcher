
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../common/helpers.mligo" "Helpers"
#import "../../batcher.mligo" "Batcher"


let add_liquidity_should_succeed =
  Breath.Model.case
  "test add liquidity"
  "should be successful if user is admin"
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
      
      let market_maker = bstorage.market_maker in
      let h_key: Batcher.user_holding_key = (btc_trader.address, token_name) in
      let vault = Option.unopt (Big_map.find_opt token_name market_maker.vaults) in
      let user_holding = Option.unopt (Big_map.find_opt h_key market_maker.user_holdings) in
      let vault_holding = Option.unopt (Big_map.find_opt user_holding market_maker.vault_holdings) in


      Breath.Result.reduce [
        act_allow_transfer
        ; act_add_liquidity
        ; Breath.Assert.is_equal "total shares should be same" deposit_amount vault.total_shares
        ; Breath.Assert.is_equal "holder should be the one that supplied liquidity" btc_trader.address vault_holding.holder
        ; Breath.Assert.is_equal "for the first liquidity , total shares hould be equal to holding shares" vault_holding.shares vault.total_shares
        ; Breath.Assert.is_equal "for the first liquidity , shares should be equal to amount" vault.native_token.amount vault.total_shares
        ; Breath.Assert.is_equal "for the first liquidity , shares should be equal to deposit amount" deposit_amount vault.total_shares
      ])


let test_suite =
  Breath.Model.suite "Suite for Add / Update Liquidity" [
    add_liquidity_should_succeed
  ]

