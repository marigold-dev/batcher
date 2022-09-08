#import "../batcher.mligo" "Batcher"
#import "util.mligo" "Util"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "../types.mligo" "CommonTypes"
#import "../orderbook.mligo" "Orderbook"
#import "../batch.mligo" "Batch"
#import "../../math_lib/lib/float.mligo" "Float"


let make_new_order_with_not_null_amount =
  Breath.Model.case
  "make_new_order"
  "Trying to make a new order with an amount > 0"
  (fun (_level: Breath.Logger.level) ->
    let (_,(alice,_,_)) = Breath.Context.init_default () in
    let alice_order = Util.make_order BUY EXACT Util.default_swap 50n alice.address in
    let expected = Util.make_order BUY EXACT Util.default_swap 10n alice.address in
    let computed = Orderbook.make_new_order alice_order 10n in

    Breath.Assert.is_true "should be equal" (expected = computed)
  )

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
      (order : Orderbook.order) =
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
      (bids : Orderbook.order list)
      (asks : Orderbook.order list) =
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
  "filter_orders"
  "Trying to push an order into the orderbook and check that the orderbook isn't empty anymore"
  (fun (_level: Breath.Logger.level) ->
    let expected = ([] : Orderbook.order list) in
    let computed = Orderbook.filter_orders ([] : Orderbook.order list) (fun (_: Orderbook.order) -> true) in

    Breath.Assert.is_true "should be equal (empty lists)" (expected = computed)
  )

let filter_minus_orderbook =
  Breath.Model.case
  "filter_orders"
  "Trying to push an order into the orderbook and check that the orderbook isn't empty anymore"
  (fun (_level: Breath.Logger.level) ->
    let (_,(alice,bob,hakim)) = Breath.Context.init_default () in

    let alice_order = Util.make_order BUY EXACT Util.default_swap 50n alice.address in
    let bob_order = Util.make_order SELL MINUS Util.default_swap 40n bob.address in
    let hakim_order = Util.make_order BUY MINUS Util.default_swap 32n hakim.address in
    
    let expected = ([alice_order] : Orderbook.order list) in
    let computed = 
      Orderbook.filter_orders [alice_order;hakim_order;bob_order] (fun (order : Orderbook.order) -> order.tolerance <> MINUS) in

    Breath.Assert.is_true "should be equal" (expected = computed)
  )

let filter_exact_orderbook =
  Breath.Model.case
  "filter_orders"
  "Trying to push an order into the orderbook and check that the orderbook isn't empty anymore"
  (fun (_level: Breath.Logger.level) ->
    let (_,(alice,bob,hakim)) = Breath.Context.init_default () in

    let alice_order = Util.make_order BUY EXACT Util.default_swap 50n alice.address in
    let bob_order = Util.make_order SELL EXACT Util.default_swap 40n bob.address in
    let hakim_order = Util.make_order BUY MINUS Util.default_swap 32n hakim.address in
    
    let expected = ([hakim_order] : Orderbook.order list) in
    let computed = 
      Orderbook.filter_orders [alice_order;hakim_order;bob_order] (fun (order : Orderbook.order) -> order.tolerance <> EXACT) in

    Breath.Assert.is_true "should be equal" (expected = computed)
  )

let filter_plus_orderbook =
  Breath.Model.case
  "filter_orders"
  "Trying to push an order into the orderbook and check that the orderbook isn't empty anymore"
  (fun (_level: Breath.Logger.level) ->
    let (_,(alice,bob,hakim)) = Breath.Context.init_default () in

    let alice_order = Util.make_order BUY PLUS Util.default_swap 50n alice.address in
    let bob_order = Util.make_order SELL MINUS Util.default_swap 40n bob.address in
    let hakim_order = Util.make_order BUY PLUS Util.default_swap 32n hakim.address in
    
    let expected = ([bob_order] : Orderbook.order list) in
    let computed = 
      Orderbook.filter_orders [alice_order;hakim_order;bob_order] (fun (order : Orderbook.order) -> order.tolerance <> PLUS) in

    Breath.Assert.is_true "should be equal" (expected = computed)
  )

let one_total_partial_match_orders =
  Breath.Model.case
  "match_orders"
  "The second order can completely fill the first one, so we get a couple (total,partial)"
  (fun (_level: Breath.Logger.level) ->
    let (_,(alice,bob,_)) = Breath.Context.init_default () in

    let alice_order = Util.make_order BUY PLUS Util.default_swap 50n alice.address in
    let bob_order = Util.make_order SELL MINUS Util.default_swap 130n bob.address in
    let remaining_bob_order = Orderbook.make_new_order bob_order 30n in
    (* very weird to have a token_amount in a swap, and a swap in a exchange_rate, what amount are we supposed to give ?
      for initiate/create a exchange_rate ? *)
    let rate = Util.make_exchange_rate (Util.default_swap 0n) (Float.new 2 0) in
    let treasury = (Big_map.empty : Util.treasury) in
    let expected = (Total, Partial remaining_bob_order) in
    let computed = 
      Orderbook.match_orders alice_order bob_order rate treasury in

    Breath.Assert.is_true "should be equal" (expected = computed)
  )

let one_partial_total_match_orders =
  Breath.Model.case
  "match_orders"
  "The first order can completely fill the second one, so we get a couple (partial,total)"
  (fun (_level: Breath.Logger.level) ->
    let (_,(alice,bob,_)) = Breath.Context.init_default () in

    let alice_order = Util.make_order BUY PLUS Util.default_swap 70n alice.address in
    let bob_order = Util.make_order SELL MINUS Util.default_swap 130n bob.address in
    let remaining_alice_order = Orderbook.make_new_order alice_order 5n in
    (* very weird to have a token_amount in a swap, and a swap in a exchange_rate, what amount are we supposed to give ?
      for initiate/create a exchange_rate ? *)
    let rate = Util.make_exchange_rate (Util.default_swap 0n) (Float.new 2 0) in
    let treasury = (Big_map.empty : Util.treasury) in
    let expected = (Partial remaining_alice_order, Total) in
    let computed = 
      Orderbook.match_orders alice_order bob_order rate treasury in

    Breath.Assert.is_true "should be equal" (expected = computed)
  )

let one_total_match_orders =
  Breath.Model.case
  "match_orders"
  "Both orders are equal in term of amount, so they fill each other up totally"
  (fun (_level: Breath.Logger.level) ->
    let (_,(alice,bob,_)) = Breath.Context.init_default () in

    let alice_order = Util.make_order BUY PLUS Util.default_swap 50n alice.address in
    let bob_order = Util.make_order SELL MINUS Util.default_swap 100n bob.address in
    (* very weird to have a token_amount in a swap, and a swap in a exchange_rate, what amount are we supposed to give ?
      for initiate/create a exchange_rate ? *)
    let rate = Util.make_exchange_rate (Util.default_swap 0n) (Float.new 2 0) in
    let treasury = (Big_map.empty : Util.treasury) in
    let expected = (Total, Total) in
    let computed = 
      Orderbook.match_orders alice_order bob_order rate treasury in

    Breath.Assert.is_true "should be equal" (expected = computed)
  )

let trigger_filtering_orders_minus =
  Breath.Model.case
  "trigger_filtering_orders"
  "trigger a filtering orders with a clearing tolerance set to minus"
  (fun (level: Breath.Logger.level) ->
    let (_,(alice,bob,hakim)) = Breath.Context.init_default () in
    let batcher = Util.originate level in

    let order1 = Util.make_order BUY MINUS Util.default_swap 150n alice.address in
    let order2 = Util.make_order BUY EXACT Util.default_swap 67n bob.address in
    let order3 = Util.make_order BUY PLUS Util.default_swap 89n hakim.address in

    let order4 = Util.make_order SELL MINUS Util.default_swap 10n alice.address in
    let order5 = Util.make_order SELL EXACT Util.default_swap 230n bob.address in
    let order6 = Util.make_order SELL PLUS Util.default_swap 30n hakim.address in

    let ord1_deposit = Breath.Context.act_as alice (Util.deposit order1 batcher 1tez) in
    let ord2_deposit = Breath.Context.act_as bob (Util.deposit order2 batcher 1tez) in
    let ord3_deposit = Breath.Context.act_as hakim (Util.deposit order3 batcher 1tez) in

    let ord4_deposit = Breath.Context.act_as alice (Util.deposit order4 batcher 1tez) in
    let ord5_deposit = Breath.Context.act_as bob (Util.deposit order5 batcher 1tez) in
    let ord6_deposit = Breath.Context.act_as hakim (Util.deposit order6 batcher 1tez) in

    let batcher_storage = Breath.Contract.storage_of batcher in
    let filtered_orderbook = 
      Breath.Assert.is_some_and
        "The current batch should be some and the orderbook should contain only the alice order"
        (fun (batch : Batch.t) ->
          let orderbook = batch.orderbook in 
          let clearing_volumes = (Map.empty : (CommonTypes.Types.tolerance, nat) map) in
          let clearing_tolerance = MINUS in
          let clearing = {
            clearing_volumes = clearing_volumes;
            clearing_tolerance = clearing_tolerance
          } in

          let computed = 
            Orderbook.trigger_filtering_orders orderbook clearing in

          let expected_orderbook : Orderbook.t = {
            bids = [order1;order2;order3];
            asks = [order4]
          } in

          Breath.Assert.is_true "should be equal" (computed = expected_orderbook)
        )
        batcher_storage.batches.current
    in
    Breath.Result.reduce [
      ord1_deposit;
      ord2_deposit;
      ord3_deposit;
      ord4_deposit;
      ord5_deposit;
      ord6_deposit;
      filtered_orderbook
    ]
  )

let trigger_filtering_orders_exact =
  Breath.Model.case
  "trigger_filtering_orders"
  "trigger a filtering orders with a clearing tolerance set to exact"
  (fun (level: Breath.Logger.level) ->
    let (_,(alice,bob,hakim)) = Breath.Context.init_default () in
    let batcher = Util.originate level in

    let order1 = Util.make_order BUY MINUS Util.default_swap 150n alice.address in
    let order2 = Util.make_order BUY EXACT Util.default_swap 67n bob.address in
    let order3 = Util.make_order BUY PLUS Util.default_swap 89n hakim.address in

    let order4 = Util.make_order SELL MINUS Util.default_swap 10n alice.address in
    let order5 = Util.make_order SELL EXACT Util.default_swap 230n bob.address in
    let order6 = Util.make_order SELL PLUS Util.default_swap 30n hakim.address in

    let ord1_deposit = Breath.Context.act_as alice (Util.deposit order1 batcher 1tez) in
    let ord2_deposit = Breath.Context.act_as bob (Util.deposit order2 batcher 1tez) in
    let ord3_deposit = Breath.Context.act_as hakim (Util.deposit order3 batcher 1tez) in

    let ord4_deposit = Breath.Context.act_as alice (Util.deposit order4 batcher 1tez) in
    let ord5_deposit = Breath.Context.act_as bob (Util.deposit order5 batcher 1tez) in
    let ord6_deposit = Breath.Context.act_as hakim (Util.deposit order6 batcher 1tez) in

    let batcher_storage = Breath.Contract.storage_of batcher in
    let filtered_orderbook = 
      Breath.Assert.is_some_and
        "The current batch should be some and the orderbook should contain only the alice order"
        (fun (batch : Batch.t) ->
          let orderbook = batch.orderbook in 
          let clearing_volumes = (Map.empty : (CommonTypes.Types.tolerance, nat) map) in
          let clearing_tolerance = EXACT in
          let clearing = {
            clearing_volumes = clearing_volumes;
            clearing_tolerance = clearing_tolerance
          } in

          let computed = 
            Orderbook.trigger_filtering_orders orderbook clearing in

          let expected_orderbook : Orderbook.t = {
            bids = [order2;order3];
            asks = [order4;order5]
          } in

          Breath.Assert.is_true "should be equal" (computed = expected_orderbook)
        )
        batcher_storage.batches.current
    in
    Breath.Result.reduce [
      ord1_deposit;
      ord2_deposit;
      ord3_deposit;
      ord4_deposit;
      ord5_deposit;
      ord6_deposit;
      filtered_orderbook
    ]
  )

let trigger_filtering_orders_plus =
  Breath.Model.case
  "trigger_filtering_orders"
  "trigger a filtering orders with a clearing tolerance set to plus"
  (fun (level: Breath.Logger.level) ->
    let (_,(alice,bob,hakim)) = Breath.Context.init_default () in
    let batcher = Util.originate level in

    let order1 = Util.make_order BUY MINUS Util.default_swap 150n alice.address in
    let order2 = Util.make_order BUY EXACT Util.default_swap 67n bob.address in
    let order3 = Util.make_order BUY PLUS Util.default_swap 89n hakim.address in

    let order4 = Util.make_order SELL MINUS Util.default_swap 10n alice.address in
    let order5 = Util.make_order SELL EXACT Util.default_swap 230n bob.address in
    let order6 = Util.make_order SELL PLUS Util.default_swap 30n hakim.address in

    let ord1_deposit = Breath.Context.act_as alice (Util.deposit order1 batcher 1tez) in
    let ord2_deposit = Breath.Context.act_as bob (Util.deposit order2 batcher 1tez) in
    let ord3_deposit = Breath.Context.act_as hakim (Util.deposit order3 batcher 1tez) in

    let ord4_deposit = Breath.Context.act_as alice (Util.deposit order4 batcher 1tez) in
    let ord5_deposit = Breath.Context.act_as bob (Util.deposit order5 batcher 1tez) in
    let ord6_deposit = Breath.Context.act_as hakim (Util.deposit order6 batcher 1tez) in

    let batcher_storage = Breath.Contract.storage_of batcher in
    let filtered_orderbook = 
      Breath.Assert.is_some_and
        "The current batch should be some and the orderbook should contain only the alice order"
        (fun (batch : Batch.t) ->
          let orderbook = batch.orderbook in 
          let clearing_volumes = (Map.empty : (CommonTypes.Types.tolerance, nat) map) in
          let clearing_tolerance = PLUS in
          let clearing = {
            clearing_volumes = clearing_volumes;
            clearing_tolerance = clearing_tolerance
          } in

          let computed = 
            Orderbook.trigger_filtering_orders orderbook clearing in

          let expected_orderbook : Orderbook.t = {
            bids = [order3];
            asks = [order4;order5;order6]
          } in

          Breath.Assert.is_true "should be equal" (computed = expected_orderbook)
        )
        batcher_storage.batches.current
    in
    Breath.Result.reduce [
      ord1_deposit;
      ord2_deposit;
      ord3_deposit;
      ord4_deposit;
      ord5_deposit;
      ord6_deposit;
      filtered_orderbook
    ]
  )


let () = 
  Breath.Model.run_suites Void [
    Breath.Model.suite "Suite for the orders matching component" [
      make_new_order_with_not_null_amount;
      one_push_order;
      many_push_order;
      filter_empty_orderbook;
      filter_minus_orderbook;
      filter_exact_orderbook;
      filter_plus_orderbook;
      one_total_partial_match_orders;
      one_partial_total_match_orders;
      one_total_match_orders;
      trigger_filtering_orders_minus;
      trigger_filtering_orders_exact;
      trigger_filtering_orders_plus
    ]
  ]