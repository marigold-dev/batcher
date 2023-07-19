#import "../../batcher.mligo" "Batcher"
#import "../tokens/fa12/main.mligo" "TZBTC"
#import "../tokens/fa2/main.mligo" "USDT"
#import "../tokens/fa2/main.mligo" "EURL"
#import "../mocks/oracle.mligo" "Oracle"
#import "./storage.mligo" "TestStorage"
#import "./utils.mligo" "TestUtils"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"

type originated = Breath.Contract.originated
type originated_contract = (Batcher.entrypoint, Batcher.storage) originated

type swap = Batcher.swap
type side = Batcher.side
type storage = Batcher.Storage.t
type tolerance = Batcher.tolerance
type valid_tokens = Batcher.valid_tokens


type test_contracts = {
   batcher:  (Batcher.entrypoint, Batcher.storage) originated;
   oracle:  (Oracle.entrypoint, Oracle.storage) originated;
   tzbtc:  (TZBTC.parameter, TZBTC.storage) originated;
   usdt:  (USDT.parameter, USDT.storage) originated;
   eurl:  (EURL.parameter, EURL.storage) originated;
}

type context = {
  btc_trader: Breath.Context.actor;
  usdt_trader: Breath.Context.actor;
  eurl_trader: Breath.Context.actor;
  admin: address;
  burn: address;
  contracts: test_contracts;
}

let originate_oracle
  (level: Breath.Logger.level)  =
  let storage = TestStorage.oracle_initial_storage in
  TestUtils.originate_oracle storage level

let originate_tzbtc
  (trader: Breath.Context.actor)
  (level: Breath.Logger.level)  =
  let storage = TestStorage.tzbtc_initial_storage trader in
  TestUtils.originate_tzbtc storage level

let originate_usdt
  (trader: Breath.Context.actor)
  (level: Breath.Logger.level)  =
  let storage = TestStorage.fa2_initial_storage trader in
  TestUtils.originate_usdt storage level

let originate_eurl
  (trader: Breath.Context.actor)
  (level: Breath.Logger.level)  =
  let storage = TestStorage.fa2_initial_storage trader in
  TestUtils.originate_eurl storage level

let originate
  (level: Breath.Logger.level)
  (tzbtc_trader: Breath.Context.actor)
  (usdt_trader: Breath.Context.actor)
  (eurl_trader: Breath.Context.actor) =
  let oracle = originate_oracle level in
  let tzbtc = originate_tzbtc tzbtc_trader level in
  let usdt = originate_usdt usdt_trader level in
  let eurl = originate_eurl eurl_trader level in
  let initial_storage = TestStorage.initial_storage oracle.originated_address tzbtc.originated_address usdt.originated_address eurl.originated_address in
  let batcher = TestUtils.originate initial_storage level in
  {
   batcher = batcher;
   oracle = oracle;
   tzbtc = tzbtc;
   usdt = usdt;
   eurl = eurl;
  }

let originate_with_admin_and_burn
  (level: Breath.Logger.level)
  (tzbtc_trader: Breath.Context.actor)
  (usdt_trader: Breath.Context.actor)
  (eurl_trader: Breath.Context.actor)
  (admin: address)
  (burn: address) =
  let oracle = originate_oracle level in
  let tzbtc = originate_tzbtc tzbtc_trader level in
  let usdt = originate_usdt usdt_trader level in
  let eurl = originate_eurl eurl_trader level in
  let initial_storage = TestStorage.initial_storage_with_admin_and_burn oracle.originated_address tzbtc.originated_address usdt.originated_address eurl.originated_address admin burn in
  let batcher = TestUtils.originate initial_storage level in
  {
   batcher = batcher;
   oracle = oracle;
   tzbtc = tzbtc;
   usdt = usdt;
   eurl = eurl;
  }

let test_context
    (level: Breath.Logger.level) = 
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in
      let burn_address = usdt_trader.address in 
      let admin_address = eurl_trader.address in 
      let contracts = originate_with_admin_and_burn level btc_trader usdt_trader eurl_trader admin_address burn_address in
      {
        btc_trader = btc_trader;
        usdt_trader = usdt_trader;
        eurl_trader = eurl_trader;
        admin = admin_address;
        burn = burn_address;
        contracts = contracts;
      }

let create_order
  (from: string)
  (to: string)
  (amount: nat)
  (side: Batcher.side)
  (tolerance: Batcher.tolerance)
  (valid_tokens: Batcher.valid_tokens) : Batcher.external_swap_order =
  let fromToken = Map.find from valid_tokens in
  let toToken = Map.find to valid_tokens in
  let nside = TestUtils.side_to_nat side in
  let swap = {
     from = {
       token = fromToken;
       amount = amount;
     };
     to = toToken;
  } in
  let ntol = TestUtils.tolerance_to_nat tolerance in
  {
    swap = swap;
    created_at = Tezos.get_now ();
    side =  nside ;
    tolerance = ntol;
  }



let place_order
  (actor: Breath.Context.actor)
  (contract: originated_contract)
  (fee: tez)
  (from: string)
  (to: string)
  (amount: nat)
  (side: Batcher.side)
  (tolerance: Batcher.tolerance)
  (valid_tokens: valid_tokens) =
  let order = create_order from to amount side tolerance valid_tokens in
  Breath.Context.act_as actor (fun (_u:unit) -> (Breath.Contract.transfer_with_entrypoint_to contract "deposit" order fee))


let expect_last_order_number
  (storage: storage)
  (last_order_number: nat)  = TestStorage.expect_from_storage "last_order_number" storage (fun s -> s.last_order_number) last_order_number

let expect_rate_value
  (storage: storage)
  (rate_name: string)
  (rate: Rational.t)  =
  match Big_map.find_opt rate_name storage.rates_current with
  | None -> Breath.Assert.fail_with "Could not find rate in storage"
  | Some r -> Breath.Assert.is_equal "rate value" r.rate rate



