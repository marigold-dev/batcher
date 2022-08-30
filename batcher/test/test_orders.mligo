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
    let alice_order = Util.make_order BUY EXACT Util.default_swap 50n alice.address in
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

let many_push_order =
  Breath.Model.case
  "push_order"
  "Trying to push an order into the orderbook and check that the orderbook isn't empty anymore"
  (fun (level: Breath.Logger.level) ->
    let (_,(alice,bob,hakim)) = Breath.Context.init_default () in
    let batcher = Util.originate level in

    let alice_order = Util.make_order BUY EXACT Util.default_swap 50n alice.address in
    let bob_order = Util.make_order SELL PLUS Util.default_swap 40n bob.address in
    let hakim_order = Util.make_order BUY PLUS Util.default_swap 32n hakim.address in

    let alice_deposit = Breath.Context.act_as alice (Util.deposit alice_order batcher 1tez) in
    let bob_deposit = Breath.Context.act_as bob (Util.deposit bob_order batcher 1tez) in
    let hakim_deposit = Breath.Context.act_as hakim (Util.deposit hakim_order batcher 1tez) in

    let batcher_storage = Breath.Contract.storage_of batcher in

    let expected_storage 
      (storage : Batcher.storage) 
      (bids : Order.order list)
      (asks : Order.order list) =
        Breath.Assert.is_some_and
          "The current batch should be some and the orderbook should contain only the alice order"
          (fun (batch : Batch.t) ->
            Breath.Result.reduce [
              Breath.Assert.is_equal "orderbook content" batch.orderbook.bids bids;
              Breath.Assert.is_equal "orderbook content" batch.orderbook.asks asks
            ]
          )
        storage.batches.current
    in

    Breath.Result.reduce [
        alice_deposit;
        bob_deposit;
        hakim_deposit;
        expected_storage batcher_storage [hakim_order;alice_order] [bob_order]
    ]
  )

let filter_empty_orderbook =
  Breath.Model.case
  "push_order"
  "Trying to push an order into the orderbook and check that the orderbook isn't empty anymore"
  (fun (level: Breath.Logger.level) ->
    let expected = ([] : Order.order list) in
    let computed = Order.filter_orders ([] : Order.order list) (fun (_: Order.order) -> true) in

    Breath.Assert.is_true "should be equal (empty lists)" (expected = computed)
  )

let filter_minus_orderbook =
  Breath.Model.case
  "push_order"
  "Trying to push an order into the orderbook and check that the orderbook isn't empty anymore"
  (fun (_level: Breath.Logger.level) ->
    let (_,(alice,bob,hakim)) = Breath.Context.init_default () in

    let alice_order = Util.make_order BUY EXACT Util.default_swap 50n alice.address in
    let bob_order = Util.make_order SELL MINUS Util.default_swap 40n bob.address in
    let hakim_order = Util.make_order BUY MINUS Util.default_swap 32n hakim.address in
    
    let expected = ([alice_order] : Order.order list) in
    let computed = 
      Order.filter_orders [alice_order;hakim_order;bob_order] (fun (order : Order.order) -> order.tolerance <> MINUS) in

    Breath.Assert.is_true "should be equal" (expected = computed)
  )

let filter_exact_orderbook =
  Breath.Model.case
  "push_order"
  "Trying to push an order into the orderbook and check that the orderbook isn't empty anymore"
  (fun (_level: Breath.Logger.level) ->
    let (_,(alice,bob,hakim)) = Breath.Context.init_default () in

    let alice_order = Util.make_order BUY EXACT Util.default_swap 50n alice.address in
    let bob_order = Util.make_order SELL EXACT Util.default_swap 40n bob.address in
    let hakim_order = Util.make_order BUY MINUS Util.default_swap 32n hakim.address in
    
    let expected = ([hakim_order] : Order.order list) in
    let computed = 
      Order.filter_orders [alice_order;hakim_order;bob_order] (fun (order : Order.order) -> order.tolerance <> EXACT) in

    Breath.Assert.is_true "should be equal" (expected = computed)
  )

let filter_plus_orderbook =
  Breath.Model.case
  "push_order"
  "Trying to push an order into the orderbook and check that the orderbook isn't empty anymore"
  (fun (_level: Breath.Logger.level) ->
    let (_,(alice,bob,hakim)) = Breath.Context.init_default () in

    let alice_order = Util.make_order BUY PLUS Util.default_swap 50n alice.address in
    let bob_order = Util.make_order SELL MINUS Util.default_swap 40n bob.address in
    let hakim_order = Util.make_order BUY PLUS Util.default_swap 32n hakim.address in
    
    let expected = ([bob_order] : Order.order list) in
    let computed = 
      Order.filter_orders [alice_order;hakim_order;bob_order] (fun (order : Order.order) -> order.tolerance <> PLUS) in

    Breath.Assert.is_true "should be equal" (expected = computed)
  )

let () = 
  Breath.Model.run_suites Void [
    Breath.Model.suite "Suite for the orders matching component" [
      one_push_order;
      many_push_order;
      filter_empty_orderbook;
      filter_minus_orderbook;
      filter_exact_orderbook;
      filter_plus_orderbook
    ]
  ]