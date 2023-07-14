#import "../../batcher.mligo" "Batcher"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"

type level = Breath.Logger.level
let log = Breath.Logger.log
type storage = Batcher.Storage.t
type originated = Breath.Contract.originated
type valid_swap = Batcher.valid_swap
type external_order = Batcher.external_swap_order
type side = Batcher.side
type tolerance = Batcher.tolerance

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
(storage: storage)
(level: level) =
  let () = log level storage in
  Breath.Contract.originate
    level
    "batcher"
    Batcher.main
    (storage: Batcher.Storage.t)
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
