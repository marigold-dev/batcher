#import "../batcher.mligo" "Batcher"
#import "util.mligo" "Util"
#import "../../breathalyzer/lib/lib.mligo" "Breath"
#import "../types.mligo" "CommonTypes"
#import "../orderbook.mligo" "Order"
#import "../batch.mligo" "Batch"

type level = Breath.Logger.level

let create_token_holding
  (holder : address)
  (token : token)
  (amount : nat) : token_holding =
  let token_amount = {
     token : token;
     amount : amount;
  } in
  {
   holder = holder;
   token_amount = token_amount;
  }


let initial_treasury
  (alice : address)
  (bob : address)
  (carol : address) : treasury =
  let tzBTC_token = {
     name = "tzBTC";
     address = ("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address)
  } in
  let usdt_token = {
    name = "usdt";
    address = ("tz1N47UGiVScUUvHemXd2kGwJi44h7qZMUzp" : address)
  } in
  Big_map.literal [
   (alice, cre)
  ]



let swap_one_token =
  Breath.Model.case
  "swap_token"
  "Trying to swap a single swap of two tokens"
  (fun (level: level) ->
    let (_,(alice,_bob,_carol)) = Breath.Context.init_default () in
    let batcher = Util.originate level in
    let alice_order = Util.make_order Util.default_swap 50n alice.address in
    let alice_deposit = Breath.Context.act_as alice (Util.deposit alice_order batcher 1tez) in
    let batcher_storage = Breath.Contract.storage_of batcher in

    let expected_storage
      (storage : Batcher.storage)
      (order : Order.order) =
        Breath.Assert.is_some_and
          "The current batch should be some and the orderbook should contain only the alice order"
          (fun (batch : Batch.t) ->
            Breath.Assert.is_equal "orderbook content" batch.orderbook.bids [order]
          )
        storage.batches.current
    in

    Breath.Result.reduce [
        alice_deposit;
        expected_storage batcher_storage alice_order
    ]
  )

let () =
  Breath.Model.run_suites Void [
    Breath.Model.suite "Suite for the treasury component" [
      one_push_order
    ]
  ]

