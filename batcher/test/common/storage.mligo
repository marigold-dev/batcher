#import "../../batcher.mligo" "Batcher"
#import "../../marketmaker.mligo" "MarketMaker"
#import "../tokens/fa12/main.mligo" "TZBTC"
#import "../tokens/fa2/main.mligo" "USDT"
#import "../tokens/fa2/main.mligo" "EURL"
#import "../../tokenmanager.mligo" "TokenManager"
#import "../../vault.mligo" "Vault"
#import "../../types.mligo" "Types"
#import "../mocks/oracle.mligo" "Oracle"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"

type level = Breath.Logger.level
type batcher_storage = Batcher.Storage.t
type mm_storage = MarketMaker.MarketMaker.storage


let fee_recipient = ("tz1burnburnburnburnburnburnburjAYjjX" :  address)
let  administrator = ("tz1aSL2gjFnfh96Xf1Zp4T36LxbzKuzyvVJ4" : address)

let tzbtc_initial_storage
  (trader: Breath.Context.actor) 
  (trader_2: Breath.Context.actor) 
  (trader_3: Breath.Context.actor) =
  let trader_address = trader.address in
  let trader_2_address = trader_2.address in
  let trader_3_address = trader_3.address in
  {
  tokens = Big_map.literal [
    ((trader_address), 90000000000n);
    ((trader_2_address), 10000000000n);
    ((trader_3_address), 10000000000n)
  ];
  allowances = (Big_map.empty : (TZBTC.allowance_key, nat) big_map);
  token_metadata = Big_map.literal [
    (0n, {
      token_id = 0n;
      token_info = Map.literal [
        ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f676c6f74746f6c6f676973742f65653736383665633638376339336131656666653331666362306131343734362f7261772f303232666332646462653534346631363466343431356266633139613131663135376630303562332f545a4254432e6a736f6e" : bytes))
      ]
    })
  ];
  total_supply = 10000000000000n;
}

let fa2_initial_storage
  (trader: Breath.Context.actor) =
  let trader_address = trader.address in
  {
  ledger = Big_map.literal [
    ((trader_address, 0n), 10000000000000n)
  ];
  token_metadata = Big_map.literal [
    (0n, {
      token_id = 0n;
      token_info = Map.literal [
        ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f676c6f74746f6c6f676973742f63633262366133396336663436313361393039623932356365653163353435362f7261772f343465373561386162633431623361336264636366323162663666373862393461313238653631312f555344542e6a736f6e" : bytes))
      ]
    })
  ];
  operators = (Big_map.empty : ((address * address), nat set) big_map)
}

let initial_storage_with_admin_and_fee_recipient
  (oracle_address: address)
  (tzbtc_address: address)
  (usdt_address:address)
  (eurl_address:address)
  (admin: address)
  (fee_recipient: address): batcher_storage = {
  metadata = (Big_map.empty : Batcher.metadata);
  valid_tokens = {
    keys = Set.literal ["tzBTC"; "EURL"; "USDT"];
    values = Big_map.literal [
    (("tzBTC"), {
      token_id = 0n;
      name = "tzBTC";
      address = Some(tzbtc_address);
      decimals = 8n;
      standard = Some "FA1.2 token"
    });
    (("EURL"),{
      token_id = 0n;
      name = "EURL";
      address = Some(eurl_address);
      decimals = 6n;
      standard = Some "FA2 token"
    });
    (("USDT"),{
      token_id = 0n;
      name = "USDT";
      address = Some(usdt_address);
      decimals = 6n;
      standard = Some "FA2 token"
    })
  ];};
  valid_swaps = {
  keys = Set.literal ["tzBTC/USDT"]; 
  values = Big_map.literal [
    ("tzBTC/USDT", {
        swap = {
            from =  "tzBTC";
            to =  "USDT";
        };
        oracle_address = oracle_address ;
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    )
  ];
  };
  rates_current = (Big_map.empty : Batcher.rates_current);
  batch_set = {
    current_batch_indices = (Map.empty : (string,nat) map);
    batches = (Big_map.empty : (nat,Batcher.batch) big_map);
  };
  last_order_number = 0n;
  user_batch_ordertypes = (Big_map.empty: Batcher.user_batch_ordertypes);
  fee_in_mutez = 10_000mutez;
  fee_recipient = fee_recipient;
  administrator = admin;
  marketmaker = admin;
  limit_on_tokens_or_pairs = 10n;
  deposit_time_window_in_seconds = 600n;
}


let initial_storage_with_admin
  (oracle_address: address)
  (tzbtc_address: address)
  (usdt_address:address)
  (eurl_address:address) 
  (admin:address) : batcher_storage = 
  initial_storage_with_admin_and_fee_recipient oracle_address tzbtc_address usdt_address eurl_address admin fee_recipient


let initial_storage
  (oracle_address: address)
  (tzbtc_address: address)
  (usdt_address:address)
  (eurl_address:address) : batcher_storage = 
  initial_storage_with_admin_and_fee_recipient oracle_address tzbtc_address usdt_address eurl_address administrator fee_recipient

let initial_mm_storage
  (oracle_address: address)
  (tzbtc_address: address)
  (usdt_address:address)
  (eurl_address:address)
  (admin: address)
  (batcher: address)
  (tokenmanager: address): mm_storage = {
  administrator = admin;
  batcher = batcher;
  tokenmanager = tokenmanager;
  vaults = {
  keys = Set.literal ["tzBTC";"EURL";"USDT"];
  values = Big_map.literal [
    ("tzBTC", tzbtc_address);
    ("EURL", eurl_address);
    ("USDT", usdt_address);
  ] ;
  };
}

let initial_tokenmanager_storage
  (administrator: address)
  (oracle_address: address)
  (tzbtc_address: address)
  (usdt_address:address)
  (eurl_address:address): TokenManager.TokenManager.storage = 
  {
    valid_tokens = {
      keys  = Set.literal ["tzBTC";"EURL";"USDT"];   
      values = Big_map.literal [

    (("tzBTC"), {
      token_id = 0n;
      name = "tzBTC";
      address = Some(tzbtc_address);
      decimals = 8n;
      standard = Some "FA1.2 token"
    });
    (("EURL"),{
      token_id = 0n;
      name = "EURL";
      address = Some(eurl_address);
      decimals = 6n;
      standard = Some "FA2 token"
    });
    (("USDT"),{
      token_id = 0n;
      name = "USDT";
      address = Some(usdt_address);
      decimals = 6n;
      standard = Some "FA2 token"
    });
  ];
  };
  valid_swaps  = {
   keys = Set.literal ["tzBTC/USDT";"tzBTC/EURL"] ;
   values = Big_map.literal [
    ("tzBTC/USDT", {
        swap = {
            from =  "tzBTC";
            to =  "USDT";
        };
        oracle_address = oracle_address;
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("tzBTC/EURL", {
        swap = {
          from = "tzBTC";
          to = "EURL";
        };
        oracle_address = oracle_address;
        oracle_asset_name = "BTC-EUR";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    )
  ];
  };
  administrator = administrator;
  limit_on_tokens_or_pairs = 10n;
}

let initial_vault_storage
  (token:Types.token)
  (administrator: address)
  (batcher: address)
  (market_maker: address)
  (tm:address) 
  (amount: nat): Vault.Vault.storage = {
  administrator = administrator;
  batcher = batcher;
  marketmaker = market_maker;
  tokenmanager = tm;
  total_shares = 0n;
  native_token = {
    token = token;
    amount = amount;
    };
  foreign_tokens = (Map.empty:(string, Vault.token_amount) map );
  vault_holdings = (Big_map.empty: (address, Vault.vault_holding) big_map);
  }


let oracle_initial_storage: Oracle.Oracle.storage =
  Map.literal [
    (("BTC-USDT"),
    {
      name = "BTC-USDT";
      value = 30000000000n;
      timestamp = Tezos.get_now ()
    }
    );
    (("BTC-EUR"),
      {
        name = "BTC-EUR";
        value = 30000000000n;
        timestamp = Tezos.get_now ()
      }
    )]

let expect_from_storage
  (type a storage)
  (name: string)
  (storage: storage)
  (selector: storage -> a)
  (expected_value: a) = Breath.Assert.is_equal name (selector storage) expected_value

