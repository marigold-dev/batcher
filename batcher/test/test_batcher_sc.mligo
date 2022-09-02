#import "../batcher.mligo" "Batcher"
#import "../types.mligo" "CommonTypes"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "util.mligo" "Util"

type level = Breath.Logger.level

(***** Batches status *****)

let alice_context (level : level) =
  let (_, (alice, _bob, _carol)) = Breath.Context.init_default () in
  let contract = Util.originate level in
  alice, contract

let default_swap (amount : nat) = {
  from = {
    token = Util.token_tzBTC;
    amount = amount
  };
  to = Util.token_USDT
}

module Bad_swaps = struct
  (* For the moment we only use such swaps in tests *)
  let with_xtz (amount : nat) = {
    from = {
      token = Util.token_XTZ;
      amount = amount
    };
    to = Util.token_USDT
  }

  let inversed_tzBTC (amount : nat) = {
    from = {
      token = Util.token_USDT;
      amount = amount
    };
    to = Util.token_tzBTC
  }
end

(* TODO: more randomness *)
let make_order (swap : nat -> CommonTypes.Types.swap) (amount : nat)
  (address : address) : CommonTypes.Types.swap_order =
  let swap = swap amount in
  let now = Tezos.get_now () in
  let order : CommonTypes.Types.swap_order = {
    trader = address;
    swap = swap;
    created_at = now;
    side = BUY;
    tolerance = EXACT
  }
  in
  order

let test_first_deposit_starts_period =
  Breath.Model.case
    "test_first_deposit_starts_period"
    "the first deposit starts the deposit period"
    (fun (level: level) ->
      let alice, contract = alice_context level in
      let order = make_order default_swap 10n alice.address in
      let alice_action = Breath.Context.act_as alice (Util.deposit order contract 5tez) in

      let storage = Breath.Contract.storage_of contract in
      let current_batch = storage.batches.current in

      Breath.Result.reduce [
        alice_action;
        Breath.Assert.is_some "The current_batch should be Some" current_batch
      ])

let test_append_order_pair_matches =
  Breath.Model.case
    "test_append_order_pair_matches"
    "the pair used by an order has to match the pair of the batch"
    (fun (level: Breath.Logger.level) ->
      let alice, contract = alice_context level in
      (* TODO: more addresses *)
      let start_order = make_order default_swap 10n alice.address in
      let correct_order = make_order default_swap 20n alice.address in
      let wrong_swap = make_order Bad_swaps.with_xtz 10n alice.address in
      let wrong_inverse_swap =
        make_order Bad_swaps.inversed_tzBTC 5n alice.address
      in
      let action1 = (* OK *)
        Breath.Context.act_as alice (Util.deposit start_order contract 5tez)
      in
      let action2 = (* FAILS *)
        Breath.Context.act_as alice (Util.deposit wrong_swap contract 5tez)
      in
      let action3 = (* OK *)
        Breath.Context.act_as alice (Util.deposit correct_order contract 5tez)
      in
      let action4 = (* FAILS *)
        Breath.Context.act_as alice (Util.deposit wrong_inverse_swap contract 5tez)
      in

      let storage = Breath.Contract.storage_of contract in
      let current_batch = storage.batches.current in

      Breath.Result.reduce [
        action1;
        Breath.Assert.is_some "The current_batch should be Some" current_batch;
        Breath.Expect.fail_with_message Batcher.Errors.order_pair_doesnt_match action2;
        action3;
        Breath.Assert.is_some "The current_batch should be Some" current_batch;
        Breath.Expect.fail_with_message Batcher.Errors.order_pair_doesnt_match action4;
      ])

let () =
  Breath.Model.run_suites Void [
    Breath.Model.suite "Suite for Batcher" [
      test_first_deposit_starts_period;
      test_append_order_pair_matches
      ]
  ]

