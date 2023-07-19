#import "../../batcher.mligo" "Batcher"
#import "../tokens/fa12/main.mligo" "TZBTC"
#import "../tokens/fa2/main.mligo" "USDT"
#import "../tokens/fa2/main.mligo" "EURL"
#import "../mocks/oracle.mligo" "Oracle"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"

type level = Breath.Logger.level
type storage = Batcher.Storage.t

let fee_recipient = ("tz1burnburnburnburnburnburnburjAYjjX" :  address)
let  administrator = ("tz1aSL2gjFnfh96Xf1Zp4T36LxbzKuzyvVJ4" : address)

let tzbtc_initial_storage
  (trader: Breath.Context.actor) =
  let trader_address = trader.address in
  {
  tokens = Big_map.literal [
    ((trader_address), 100000000000n)
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

let initial_storage_with_admin_and_burn
  (oracle_address: address)
  (tzbtc_address: address)
  (usdt_address:address)
  (eurl_address:address)
  (admin: address)
  (burn: address): storage = {
  metadata = (Big_map.empty : Batcher.metadata);
  valid_tokens = Map.literal [
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
  ];
  valid_swaps = Map.literal [
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
  rates_current = (Big_map.empty : Batcher.rates_current);
  batch_set = {
    current_batch_indices = (Map.empty : (string,nat) map);
    batches = (Big_map.empty : (nat,Batcher.batch) big_map);
  };
  last_order_number = 0n;
  user_batch_ordertypes = (Big_map.empty: Batcher.user_batch_ordertypes);
  fee_in_mutez = 10_000mutez;
  fee_recipient = burn;
  administrator = admin;
  limit_on_tokens_or_pairs = 10n;
  deposit_time_window_in_seconds = 600n;
  scale_factor_for_oracle_staleness = 1n
}




let initial_storage
  (oracle_address: address)
  (tzbtc_address: address)
  (usdt_address:address)
  (eurl_address:address) : storage = 
  initial_storage_with_admin_and_burn oracle_address tzbtc_address usdt_address eurl_address administrator fee_recipient

let oracle_initial_storage =
  Map.literal [
    (("tzBTC/USDT"),
    {
      name = "tzBTC/USDT";
      value = 20000000000n;
      timestamp = Tezos.get_now ()
    }
    );
    (("tzBTC/EURL"),
      {
        name = "tzBTC/EURL";
        value = 20000000000n;
        timestamp = Tezos.get_now ()
      }
    )]

let expect_from_storage
  (type a)
  (name: string)
  (storage: storage)
  (selector: storage -> a)
  (expected_value: a) = Breath.Assert.is_equal name (selector storage) expected_value

