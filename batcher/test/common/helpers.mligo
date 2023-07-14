#import "../../batcher.mligo" "Batcher"
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

let originate
  (level: Breath.Logger.level)  =
  let initial_storage = TestStorage.initial_storage in
  TestUtils.originate initial_storage level

let originate_with_rate
  (level: Breath.Logger.level)
  (pair_name: string)
  (to: string)
  (from: string)
  (rate: nat)  =
  let initial_storage = TestStorage.initial_storage in
  let scaled = rate * 100000000n in
  let updated_rates = TestUtils.update_rate pair_name from to scaled 100000000n  initial_storage.rates_current in
  let storage_with_updated_rate = { initial_storage with rates_current = updated_rates; } in
  TestUtils.originate storage_with_updated_rate level

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
  let _  = Breath.Assert.is_equal "from token address" fromToken.address (Some TestStorage.btc_address) in
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



