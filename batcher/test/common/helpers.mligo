#import "../../batcher.mligo" "Batcher"
#import "../../marketmaker.mligo" "MarketMaker"
#import "../../tokenmanager.mligo" "TokenManager"
#import "../../vault.mligo" "Vault"
#import "../tokens/fa12/main.mligo" "TZBTC"
#import "../tokens/fa2/main.mligo" "USDT"
#import "../tokens/fa2/main.mligo" "EURL"
#import "../mocks/oracle.mligo" "Oracle"
#import "./storage.mligo" "TestStorage"
#import "./utils.mligo" "TestUtils"
#import "../../utils.mligo" "CommonUtils"
#import "../../types.mligo" "CommonTypes"
#import "./batch.mligo" "TestBatch"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"

type originated = Breath.Contract.originated
type originated_batcher_contract = (Batcher.entrypoint, Batcher.storage) originated
type originated_mm_contract = (MarketMaker.entrypoint, MarketMaker.MarketMaker.storage) originated
type originated_tm_contract = (TokenManager.entrypoint, TokenManager.TokenManager.storage) originated
type originated_vault_contract = (Vault.entrypoint, Vault.Vault.storage) originated
type originated_tzbtc_contract = (TZBTC.parameter, TZBTC.storage) originated
type originated_usdt_contract = (USDT.parameter, USDT.storage) originated
type originated_eurl_contract = (EURL.parameter, EURL.storage) originated
type originated_oracle_contract = (Oracle.entrypoint, Oracle.Oracle.storage) originated

type swap = Batcher.swap
type side = Batcher.side
type storage = Batcher.Storage.t
type tolerance = Batcher.tolerance
type level = Breath.Logger.level

type test_contracts = {
   batcher:  (Batcher.entrypoint, Batcher.storage) originated;
   marketmaker:  (MarketMaker.entrypoint, MarketMaker.MarketMaker.storage) originated;
   tokenmanager:  (TokenManager.entrypoint, TokenManager.TokenManager.storage) originated;
   oracle: originated_oracle_contract;
   additional_oracle: originated_oracle_contract;
   tzbtc: originated_tzbtc_contract;
   usdt:  originated_usdt_contract;
   eurl:  originated_eurl_contract;
   tzbtc_vault:  (Vault.entrypoint, Vault.Vault.storage) originated;
   usdt_vault:  (Vault.entrypoint, Vault.Vault.storage) originated;
   eurl_vault:  (Vault.entrypoint, Vault.Vault.storage) originated;
}

type context = {
  btc_trader: Breath.Context.actor;
  usdt_trader: Breath.Context.actor;
  eurl_trader: Breath.Context.actor;
  admin: Breath.Context.actor;
  non_admin: Breath.Context.actor;
  fee_recipient: address;
  contracts: test_contracts;
}
let originate_module
  (type a b)
  (level: level)
  (name: string)
  (contract: (a, b) module_contract)
  (storage: b)
  (quantity: tez) : (a, b) originated =
  let typed_address, _, _ = Test.originate_module contract storage quantity in
  let contract = Test.to_contract typed_address in
  let address = Tezos.address contract in

  let () =
    Breath.Logger.log level ("originated smart contract", name, address, storage, quantity)
  in
  { originated_typed_address = typed_address
  ; originated_contract = contract
  ; originated_address = address }

let originate_oracle
  (level: Breath.Logger.level) : originated_oracle_contract =
  let storage = TestStorage.oracle_initial_storage in
  TestUtils.originate_oracle storage level

let originate_tzbtc
  (trader: Breath.Context.actor)
  (trader_2: Breath.Context.actor)
  (trader_3: Breath.Context.actor)
  (level: Breath.Logger.level)  =
  let storage = TestStorage.tzbtc_initial_storage trader trader_2 trader_3 in
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

let originate_tokens
  (level: Breath.Logger.level)
  (tzbtc_trader: Breath.Context.actor)
  (usdt_trader: Breath.Context.actor)
  (eurl_trader: Breath.Context.actor) =
  let tzbtc = originate_tzbtc tzbtc_trader usdt_trader eurl_trader level in
  let usdt = originate_usdt usdt_trader level in
  let eurl = originate_eurl eurl_trader level in
  (tzbtc,usdt, eurl)

let originate_tm
  (level: Breath.Logger.level)
  (tzbtc_trader: Breath.Context.actor)
  (usdt_trader: Breath.Context.actor)
  (eurl_trader: Breath.Context.actor)
  (admin: Breath.Context.actor): (originated_tm_contract * originated_oracle_contract * originated_oracle_contract * originated_tzbtc_contract * originated_usdt_contract * originated_eurl_contract) =
  let (tzbtc,usdt,eurl) = originate_tokens level tzbtc_trader usdt_trader eurl_trader in
  let oracle = originate_oracle level in
  let additional_oracle = originate_oracle level in
  let initial_tm_storage = TestStorage.initial_tokenmanager_storage admin.address oracle.originated_address tzbtc.originated_address  usdt.originated_address eurl.originated_address in
  let tm =TestUtils.originate_tm initial_tm_storage level in
  (tm,oracle,additional_oracle,tzbtc,usdt,eurl)

let originate_vault_contract
  (token:CommonTypes.token)
  (amount:nat)
  (batcher: originated_batcher_contract)
  (marketmaker: originated_mm_contract )
  (tm:originated_tm_contract )
  (admin: Breath.Context.actor)
  (level: Breath.Logger.level): originated_vault_contract =
  let stor = TestStorage.initial_vault_storage token admin.address batcher.originated_address marketmaker.originated_address  tm.originated_address amount in
  TestUtils.originate_vault token.name stor level

let originate_vault_contracts
   (batcher: originated_batcher_contract)
   (marketmaker: originated_mm_contract )
   (tm:originated_tm_contract )
   (admin: Breath.Context.actor) 
   (level: Breath.Logger.level): (originated_vault_contract * originated_vault_contract * originated_vault_contract)= 
   let tokens = CommonUtils.TokenManagerUtils.get_valid_tokens tm.originated_address in 
   let tzbtc_token = Option.unopt (Map.find_opt "tzBTC" tokens) in
   let usdt_token = Option.unopt (Map.find_opt "USDT" tokens) in
   let eurl_token = Option.unopt (Map.find_opt "EURL" tokens) in
   let tzbtc_vault = originate_vault_contract tzbtc_token 0n batcher marketmaker tm admin level in
   let usdt_vault = originate_vault_contract usdt_token 0n batcher marketmaker tm admin level in
   let eurl_vault = originate_vault_contract eurl_token 0n batcher marketmaker tm admin level in
   (tzbtc_vault,usdt_vault, eurl_vault)
  

let originate_with_admin
  (level: Breath.Logger.level)
  (tzbtc_trader: Breath.Context.actor)
  (usdt_trader: Breath.Context.actor)
  (eurl_trader: Breath.Context.actor)
  (admin: Breath.Context.actor) =
  let tzbtc = originate_tzbtc tzbtc_trader usdt_trader eurl_trader level in
  let usdt = originate_usdt usdt_trader level in
  let eurl = originate_eurl eurl_trader level in
  let  (tm,oracle,additional_oracle,tzbtc,usdt,eurl) = originate_tm level tzbtc_trader usdt_trader eurl_trader admin in
  let initial_storage = TestStorage.initial_storage_with_admin oracle.originated_address tzbtc.originated_address usdt.originated_address eurl.originated_address admin.address in
  let batcher = TestUtils.originate initial_storage level in
  let initial_mm_storage: MarketMaker.MarketMaker.storage = TestStorage.initial_mm_storage oracle.originated_address tzbtc.originated_address usdt.originated_address eurl.originated_address admin.address batcher.originated_address tm.originated_address in
  let mm: originated_mm_contract = TestUtils.originate_mm initial_mm_storage level in
  let (tzbtc_vault,usdt_vault, eurl_vault) = originate_vault_contracts batcher mm tm admin level in
  {
   batcher = batcher;
   marketmaker = mm;
   tokenmanager = tm;
   oracle = oracle;
   additional_oracle = additional_oracle;
   tzbtc = tzbtc;
   usdt = usdt;
   eurl = eurl;
   tzbtc_vault = tzbtc_vault;
   usdt_vault = usdt_vault;
   eurl_vault = eurl_vault;
  }

let originate_with_admin_and_fee_recipient
  (level: Breath.Logger.level)
  (tzbtc_trader: Breath.Context.actor)
  (usdt_trader: Breath.Context.actor)
  (eurl_trader: Breath.Context.actor)
  (admin: Breath.Context.actor)
  (fee_recipient: address) =
  let tzbtc = originate_tzbtc tzbtc_trader usdt_trader eurl_trader level in
  let usdt = originate_usdt usdt_trader level in
  let eurl = originate_eurl eurl_trader level in
  let (tm,oracle,additional_oracle,tzbtc,usdt,eurl) = originate_tm level tzbtc_trader usdt_trader eurl_trader admin in
  let initial_storage = TestStorage.initial_storage_with_admin_and_fee_recipient oracle.originated_address tzbtc.originated_address usdt.originated_address eurl.originated_address admin.address fee_recipient in
  let batcher = TestUtils.originate initial_storage level in
  let initial_mm_storage = TestStorage.initial_mm_storage oracle.originated_address tzbtc.originated_address usdt.originated_address eurl.originated_address admin.address batcher.originated_address tm.originated_address in
  let mm : originated_mm_contract = TestUtils.originate_mm initial_mm_storage level in
  let (tzbtc_vault,usdt_vault, eurl_vault) = originate_vault_contracts batcher mm tm admin level in
  let contracts: test_contracts = {
   batcher = batcher;
   marketmaker = mm;
   tokenmanager = tm;
   oracle = oracle;
   additional_oracle = additional_oracle;
   tzbtc = tzbtc;
   usdt = usdt;
   eurl = eurl;
   tzbtc_vault = tzbtc_vault;
   usdt_vault = usdt_vault;
   eurl_vault = eurl_vault;
  } in
  contracts

let originate_with_batch_for_clearing
  (level: Breath.Logger.level)
  (tzbtc_trader: Breath.Context.actor)
  (usdt_trader: Breath.Context.actor)
  (eurl_trader: Breath.Context.actor)
  (batch: Batcher.batch)
  (admin: Breath.Context.actor)
  (pair: string)  =
  let tzbtc = originate_tzbtc tzbtc_trader usdt_trader eurl_trader level in
  let usdt = originate_usdt usdt_trader level in
  let eurl = originate_eurl eurl_trader level in
  let  (tm,oracle,additional_oracle,tzbtc,usdt,eurl) = originate_tm level tzbtc_trader usdt_trader eurl_trader admin in
  let initial_storage = TestStorage.initial_storage oracle.originated_address tzbtc.originated_address usdt.originated_address eurl.originated_address in
  let batch_set = initial_storage.batch_set in
  let cbi = Map.add pair 1n batch_set.current_batch_indices in
  let batches = Big_map.add 1n batch batch_set.batches in
  let batch_set = { batch_set with 
    current_batch_indices = cbi;
    batches = batches
  } in
  let initial_storage = { initial_storage with batch_set = batch_set; }
  in
  let batcher = TestUtils.originate initial_storage level in
  let initial_mm_storage = TestStorage.initial_mm_storage oracle.originated_address tzbtc.originated_address usdt.originated_address eurl.originated_address admin.address batcher.originated_address tm.originated_address in
  let mm : originated_mm_contract = TestUtils.originate_mm initial_mm_storage level in
  let (tzbtc_vault,usdt_vault, eurl_vault) = originate_vault_contracts batcher mm tm admin level in
  {
   batcher = batcher;
   marketmaker = mm;
   tokenmanager = tm;
   oracle = oracle;
   additional_oracle = additional_oracle;
   tzbtc = tzbtc;
   usdt = usdt;
   eurl = eurl;
   tzbtc_vault = tzbtc_vault;
   usdt_vault = usdt_vault;
   eurl_vault = eurl_vault;
  }

let test_context
    (level: Breath.Logger.level) = 
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in
      let fee_recipient_address = usdt_trader.address in 
      let contracts:test_contracts = originate_with_admin_and_fee_recipient level btc_trader usdt_trader eurl_trader eurl_trader fee_recipient_address in
      {
        btc_trader = btc_trader;
        usdt_trader = usdt_trader;
        eurl_trader = eurl_trader;
        admin = eurl_trader;
        non_admin = btc_trader;
        fee_recipient = fee_recipient_address;
        contracts = contracts;
      }

let test_context_with_batch
    (pair: string)
    (batch: Batcher.batch)
    (level: Breath.Logger.level) = 
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in
      let fee_recipient_address = usdt_trader.address in 
      let contracts = originate_with_batch_for_clearing level btc_trader usdt_trader eurl_trader batch pair in
      {
        btc_trader = btc_trader;
        usdt_trader = usdt_trader;
        eurl_trader = eurl_trader;
        admin = eurl_trader;
        non_admin = btc_trader;
        fee_recipient = fee_recipient_address;
        contracts = contracts;
      }

let create_order
  (from: string)
  (to: string)
  (amount: nat)
  (side: Batcher.side)
  (tolerance: Batcher.tolerance)
  (valid_tokens: CommonTypes.ValidTokens.t) : Batcher.external_swap_order =
  let fromToken = CommonTypes.ValidTokens.find_or_fail from valid_tokens in
  let toToken = CommonTypes.ValidTokens.find_or_fail to valid_tokens in
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
  (valid_tokens: CommonTypes.ValidTokens.t) =
  let order = create_order from to amount side tolerance valid_tokens in
  Breath.Context.act_as actor (fun (_u:unit) -> (Breath.Contract.transfer_to contract (Deposit order) fee))

let add_liquidity
  (actor: Breath.Context.actor)
  (contract: originated_vault_contract)
  (amount: nat) = 
  Breath.Context.act_as actor (fun (_u:unit) -> (Breath.Contract.transfer_to contract (AddLiquidity amount) 0tez))

let remove_liquidity
  (actor: Breath.Context.actor)
  (contract: originated_vault_contract) =
  Breath.Context.act_as actor (fun (_u:unit) -> (Breath.Contract.transfer_to contract (RemoveLiquidity ()) 0tez))

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

let get_swap_pair
   (contract: originated_tm_contract) 
   (pair: string): TokenManager.valid_swap_reduced option = 
   let storage = Breath.Contract.storage_of contract in
   let valid_swaps = storage.valid_swaps in
   CommonTypes.ValidSwaps.find_opt pair valid_swaps

let get_source_update
  (pair: string)
  (valid_swap: Batcher.valid_swap_reduced)
  (new_oracle_address: address) : Batcher.oracle_source_change = 
  {
    pair_name = pair;
    oracle_address = new_oracle_address;
    oracle_asset_name = valid_swap.oracle_asset_name;
    oracle_precision = valid_swap.oracle_precision;
  }


let get_current_batch
  (pair: string)
  (storage: Batcher.Storage.t): Batcher.batch option = 
  let batch_set = storage.batch_set in 
  match Map.find_opt pair batch_set.current_batch_indices with
  | Some i -> Big_map.find_opt i batch_set.batches
  | None -> None



type balances = {
   tzbtc : nat;
   usdt: nat;
   eurl: nat;
}

let get_balances
  (holder: address)
  (tzbtc_contract:  (TZBTC.parameter, TZBTC.storage) originated)
  (usdt_contract:  (USDT.parameter, USDT.storage) originated)
  (eurl_contract:  (EURL.parameter, EURL.storage) originated) : balances = 
  let tzbtc_storage = Breath.Contract.storage_of tzbtc_contract in 
  let eurl_storage = Breath.Contract.storage_of usdt_contract in 
  let usdt_storage = Breath.Contract.storage_of eurl_contract in 
  let tzbtc_balance = match Big_map.find_opt holder tzbtc_storage.tokens with
                       | None -> 0n
                       | Some v -> v
  in
  let usdt_balance  =  match Big_map.find_opt (holder,0n) usdt_storage.ledger with
                       | None -> 0n
                       | Some v -> v
  in
  let eurl_balance  =  match Big_map.find_opt (holder,0n) eurl_storage.ledger with
                       | None -> 0n
                       | Some v -> v
  in
  {
     tzbtc = tzbtc_balance;
     usdt = usdt_balance;
     eurl = eurl_balance;
  }


