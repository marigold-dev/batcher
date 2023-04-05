#import "../batcher.mligo" "Batcher"
#import "test_mock_oracle.mligo" "Oracle"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"

type level = Breath.Logger.level
let log = Breath.Logger.log
type storage = Batcher.Storage.t
type originated = Breath.Contract.originated
type valid_swap = Batcher.valid_swap
type external_order = Batcher.external_swap_order

let originate 
(storage: storage)
(level: level) =
  let () = log level storage in
  Breath.Contract.originate
    level
    "batcher_sc"
    Batcher.main
    (storage: Batcher.Storage.t)
    (0tez)

let originate_oracle 
(level: level) =
  Breath.Contract.originate
    level
    "oracle_sc"
    Oracle.main
    (None: Oracle.storage)
    (0tez)

let trader_one_context
 (storage: storage)
 (level : level) =
  let (_, (trader_one, _trader_two, _trader_three)) = Breath.Context.init_default () in
  let contract = originate storage level in
  trader_one, contract

let trader_two_context 
 (storage: storage)
 (level : level) =
  let (_, (trader_one, _trader_two, _trader_three)) = Breath.Context.init_default () in
  let contract = originate storage level in
  trader_one, contract

let trader_one_context 
 (storage: storage)
 (level : level) =
  let (_, (trader_one, _trader_two, _trader_three)) = Breath.Context.init_default () in
  let contract = originate storage level in
  trader_one, contract

let create_rate
  (num: nat)
  (denom: nat) : Rational.t = 
  let r_num = Rational.new (int num) in 
  let r_denom = Rational.new (int denom) in
  Rational.div r_num r_denom

let create_rate_update
  (value: nat)
  (when: timestamp option) : Oracle.rate_update = 
  match when with
  | None   -> let ts = Tezos.get_now () in
            { value = value; timestamp = ts;}
  | Some t -> { value = value; timestamp = t;}

let deposit (order : external_order)
  (contract : (Batcher.entrypoint, Batcher.storage) originated)
  (fee: tez)
  () =
  let deposit_end = Deposit order in
  Breath.Contract.transfer_to contract deposit_end fee

let tick
  (asset: string)
  (contract : (Batcher.entrypoint, Batcher.storage) originated)
  (fee: tez)
  () =
  let tick_end = Tick asset in
  Breath.Contract.transfer_to contract tick_end fee

let update_oracle
  (oracle : (Oracle.entrypoint, Oracle.storage) originated)
  (update: Oracle.rate_update)
  (fee: tez)
  () =
  let update_end = Update update in
  Breath.Contract.transfer_to oracle update_end fee