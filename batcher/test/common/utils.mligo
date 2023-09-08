#import "../../batcher.mligo" "Batcher"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"
#import "../tokens/fa12/main.mligo" "TZBTC"
#import "../tokens/fa2/main.mligo" "USDT"
#import "../tokens/fa2/main.mligo" "EURL"
#import "../mocks/oracle.mligo" "Oracle"
#import "./storage.mligo" "TestStorage"
#import "../../marketmaker.mligo" "MarketMaker"

type level = Breath.Logger.level
let log = Breath.Logger.log
type batcher_storage = Batcher.Storage.t
type mm_storage = MarketMaker.Storage.t
type originated = Breath.Contract.originated
type valid_swap = Batcher.valid_swap
type external_order = Batcher.external_swap_order
type side = Batcher.side
type tolerance = Batcher.tolerance
type oracle_storage = Oracle.storage
type tzbtc_storage = TZBTC.storage
type usdt_storage = USDT.storage
type eurl_storage = EURL.storage



let side_to_nat
(order_side : side) : nat =
  if order_side = Buy then 0n
  else
    1n

let tolerance_to_nat (tolerance : tolerance) : nat =
  if tolerance = Minus then 0n
  else if tolerance = Exact then 1n
  else 2n

let originate
(storage: batcher_storage)
(level: level) =
  let () = log level storage in
  Breath.Contract.originate_uncurried
    level
    "batcher"
    (Batcher.main)
    (storage)
    (0tez)

let originate_mm
(storage: mm_storage)
(level: level) =
  let () = log level storage in
  Breath.Contract.originate_uncurried
    level
    "marketmaker"
    (MarketMaker.main)
    (storage)
    (0tez)

let originate_oracle
(storage: oracle_storage)
(level: level) =
  let () = log level storage in
  Breath.Contract.originate_module
    level
    "oracle"
    (contract_of Oracle)
    (storage)
    (0tez)

let originate_tzbtc
  (storage: tzbtc_storage)
  (level: level) =
  let () = log level storage in
  Breath.Contract.originate_uncurried
    level
    "tzbtc"
    TZBTC.main
    (storage)
    (0tez)

let originate_usdt
  (storage: usdt_storage)
  (level: level) =
  let () = log level storage in
  Breath.Contract.originate_uncurried
    level
    "usdt"
    USDT.main
    (storage)
    (0tez)

let originate_eurl
  (storage: eurl_storage)
  (level: level) =
  let () = log level storage in
  Breath.Contract.originate_uncurried
    level
    "eurl"
    EURL.main
    (storage)
    (0tez)

let update_rate
  (pair_name: string)
  (from: string)
  (to: string)
  (num: nat)
  (denom: nat)
  (rates : Batcher.rates_current): Batcher.rates_current =
  let r_num = Rational.new (int num) in
  let r_denom = Rational.new (int denom) in
  let rate = Rational.div r_num r_denom in
  let swap = {
    from = from;
    to = to;
  } in
  let ex_rate = {
    swap = swap;
    rate = rate;
    when = Tezos.get_now ()
  } in
  Big_map.update pair_name (Some ex_rate) rates


  
let expecte_fail_with_value (type a) (value: a) (result: Breath.Result.result) : Breath.Result.result =
  match result with
  | Failed [Execution (Rejected (mp, _))] ->
    let value_mp = Test.compile_value value in
    if Test.michelson_equal mp value_mp then Breath.Result.succeed
    else
      let full_value =
        "Expected failure: `"
        ^ (Test.to_string value) ^ "` but: `"
        ^ (Test.to_string mp)
        ^ "` given"
      in
      Breath.Result.fail_with full_value
  | _ -> Breath.Result.fail_with ("Expected failure: `" ^ (Test.to_string value) ^ "`")
