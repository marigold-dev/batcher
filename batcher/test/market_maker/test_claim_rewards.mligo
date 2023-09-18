
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../common/helpers.mligo" "Helpers"
#import "../../batcher.mligo" "Batcher"
#import "../../marketmaker.mligo" "MarketMaker"
#import "../../errors.mligo" "Errors"


let claim_should_fail_with_zero_unclaimed =
  Breath.Model.case
  "test claim"
  "should fail with zero unclaimed"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let mm = context.contracts.marketmaker in
      let btc_trader = context.btc_trader in 

      let bstorage = Breath.Contract.storage_of mm in

       let token_name = "tzBTC" in

      let deposit_amount = 2000000n in
      let allowance = {
        spender = mm.originated_address;
        value = deposit_amount
       } in
      let act_allow_transfer =   Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to context.contracts.tzbtc (Approve allowance) 0tez)) in
      let act_add_liquidity = Helpers.add_liquidity btc_trader mm token_name deposit_amount bstorage.valid_tokens in
      let act_claim = Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to mm (Claim token_name) 0tez)) in
      

      Breath.Result.reduce [
        act_allow_transfer
        ; act_add_liquidity
        ; Breath.Expect.fail_with_value Errors.no_holdings_to_claim act_claim
      ])

let test_suite =
  Breath.Model.suite "Suite for Claim Rewards" [
    claim_should_fail_with_zero_unclaimed
  ]
