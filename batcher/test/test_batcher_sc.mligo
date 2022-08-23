#import "../batcher.mligo" "Batcher"
#import "../types.mligo" "CommonTypes"
#import "../../breathalyzer/lib/lib.mligo" "Breath"
#import "util.mligo" "Util"


(***** Timestamps *****)

let test_first_deposit_starts_period =
  Breath.Model.case
    "test_first_deposit_starts_period"
    "the first deposit starts the deposit period"
    (fun (level: Breath.Logger.level) ->
      let (_, (alice, _bob, _carol)) = Breath.Context.init_default () in
      let _contract = Util.originate level in

      (* TODO: more data? Random data? *)
      let swap = {
        from = {
          token = Util.token_tzBTC;
          amount = 10n
        };
        to = Util.token_USDT
      }
      in
      let now = Tezos.get_now () in
      let order : CommonTypes.Types.swap_order = {
        trader = alice.address;
        swap = swap;
        created_at = now;
        side = BUY;
        tolerance = EXACT
      }
      in
      let ( _, storage ) = Breath.Context.act_as alice (Util.deposit order Util.initial_storage) in
      let current_batch = storage.batches.current in
      Breath.Assert.is_some "The current_batch should be Some" current_batch)

let () =
  Breath.Model.run_suites Trace [
    Breath.Model.suite "Suite for Batcher" [
      test_first_deposit_starts_period
      ]
  ]

