#import "../batcher.mligo" "Batcher"
#import "util.mligo" "Util"
#import "../../breathalyzer/lib/lib.mligo" "Breath"
#import "../types.mligo" "CommonTypes"
#import "../orderbook.mligo" "Order"
#import "../batch.mligo" "Batch"

let one_push_order =
  Breath.Model.case
  "push_order"
  "Trying to push an order into the orderbook and check that the orderbook isn't empty anymore"
  (fun (level: Breath.Logger.level) ->
    let (_,(alice,_,_)) = Breath.Context.init_default () in
    let batcher = Util.originate level in
    let alice_order = Util.make_order Util.default_swap 50n alice.address in
    let alice_deposit = Breath.Context.act_as alice (Util.deposit alice_order batcher 1tez) in
    let batcher_storage = Breath.Contract.storage_of batcher in

    let expected_storage 
      (storage : Batcher.storage) 
      (order : Order.order) =
        let key = (order.side, order.tolerance) in
        Breath.Assert.is_some_and
            "The orderbook should contain only alice order"
            (fun (order_found : Order.order list) ->
            let expected_value =
                Breath.Assert.is_equal "orderbook content" order_found [order] in
            Breath.Result.reduce [
                expected_value
            ]
            )
            (Big_map.find_opt key storage.orders : Order.order list option)
    in

    Breath.Result.reduce [
        alice_deposit;
        expected_storage batcher_storage alice_order
    ]
  )

let () = 
  Breath.Model.run_suites Void [
    Breath.Model.suite "Suite for the orders matching component" [
      one_push_order
    ]
  ]