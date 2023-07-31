#import "../../batcher.mligo" "Batcher"
type pressure = Buy | Sell
type skew = 
NoSkew
| Balanced
| Negative
| Postitive
| LargePositive
| LargeNegative
| PositiveAllBetter
| NegativeAllBetter
| PostitiveAllWorse
| NegativeAllWorse

type tolerance = Batcher.tolerance
type batch = Batcher.batch


type side_test_volumes = {
    minus: nat;
    exact: nat;
    plus: nat;
}

type clearing_test_case = {
    buy_minus: nat;
    buy_exact: nat;
    buy_plus: nat;
    sell_minus: nat;
    sell_exact: nat;
    sell_plus: nat;
    expected: tolerance;
}

let buy_pressure_cases: (skew,clearing_test_case) map =  Map.literal [
(NoSkew, {
     buy_minus = 1000000n;
     buy_exact = 2000000n;
     buy_plus = 3000000n;
     sell_minus = 0n;
     sell_exact = 0n;
     sell_plus = 0n;
     expected = Minus;
 })]

let sell_pressure_cases: (skew,clearing_test_case) map =  Map.literal [
(NoSkew,{
     buy_minus = 0n;
     buy_exact = 0n;
     buy_plus = 0n;
     sell_minus = 200000000n;
     sell_exact = 400000000n;
     sell_plus = 600000000n;
   expected = Minus;
 })]

let empty_volumes: Batcher.volumes = {
      buy_minus_volume = 0n;
      buy_exact_volume = 0n;
      buy_plus_volume = 0n;
      buy_total_volume = 0n;
      sell_minus_volume = 0n;
      sell_exact_volume = 0n;
      sell_plus_volume = 0n;
      sell_total_volume = 0n;
    }

let add_volumes_to_batch
  (buy_minus_volume : nat)
  (buy_exact_volume : nat)
  (buy_plus_volume : nat)
  (sell_minus_volume : nat)
  (sell_exact_volume : nat)
  (sell_plus_volume : nat)
  (batch: batch) : batch =
  let volumes = {
    buy_plus_volume = buy_plus_volume;
    buy_exact_volume = buy_exact_volume;
    buy_minus_volume = buy_minus_volume;
    buy_total_volume = buy_exact_volume + buy_minus_volume + buy_plus_volume;
    sell_minus_volume = sell_minus_volume;
    sell_plus_volume = sell_plus_volume;
    sell_exact_volume = sell_plus_volume;
    sell_total_volume = sell_exact_volume + sell_minus_volume + sell_plus_volume;
  } in 
  { batch with volumes = volumes; }

 
let prepare_batch
  (pair: string * string)
  (pressure:pressure)
  (skew:skew) : (tolerance * batch) = 
  let status = Closed  { start_time = Tezos.get_now () - 1000 ; closing_time = Tezos.get_now () - 200 } in
  let batch = {
  batch_number = 1n;
  status = status;
  volumes = empty_volumes;
  pair = pair;
  holdings = 0n;
  } in
  let test_cases = if pressure = Buy then
                     buy_pressure_cases
                   else
                     sell_pressure_cases
  in
  let test_case = Option.unopt (Map.find_opt skew test_cases) in
  let batch = add_volumes_to_batch test_case.buy_minus test_case.buy_exact test_case.buy_plus test_case.sell_minus test_case.sell_exact test_case.sell_plus batch in
  (test_case.expected, batch)
  

let prepare_all_batches_for_clearing
  (pair: string * string) : (tolerance * batch) list = 
  [
   prepare_batch pair Buy NoSkew;
   (* prepare_batch pair Buy Balanced;
   prepare_batch pair Buy Negative;
   prepare_batch pair Buy Positive;
   prepare_batch pair Buy LargePositive;
   prepare_batch pair Buy LargeNegative;
   prepare_batch pair Buy PositiveAllBetter;
   prepare_batch pair Buy NegativeAllBetter;
   prepare_batch pair Buy PositiveAllWorse;
   prepare_batch pair Buy NegativeAllWorse; *)
   prepare_batch pair Sell NoSkew;
   (* prepare_batch pair Sell Balanced;
   prepare_batch pair Sell Negative;
   prepare_batch pair Sell Positive;
   prepare_batch pair Sell LargePositive;
   prepare_batch pair Sell LargeNegative;
   prepare_batch pair Sell PositiveAllBetter;
   prepare_batch pair Sell NegativeAllBetter;
   prepare_batch pair Sell PositiveAllWorse;
   prepare_batch pair Sell NegativeAllWorse; *)
  ]
