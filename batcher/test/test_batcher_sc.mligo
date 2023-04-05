#import "../batcher.mligo" "Batcher"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"
#import "test_storage.mligo" "TestStorage"
#import "test_utils.mligo" "TestUtils"

type level = Breath.Logger.level


let test_can_originate_contract =
  fun (level: level) ->    
      let () = Breath.Logger.log level "Originate Batcher contract" in
      let oracle = TestUtils.originate_oracle level in
      let initial_storage = TestStorage.initial_storage oracle.originated_address in  
      let contract = TestUtils.originate initial_storage level in
      let storage = Breath.Contract.storage_of contract in
      let balance = Breath.Contract.balance_of contract in

      Breath.Result.reduce [
        Breath.Assert.is_equal "balance" balance 0tez
      ; TestStorage.Helpers.expect_last_order_number storage 0n
      ]

let test_swap_deposit_starts_batch = 
  fun (level: level) ->    
      let () = Breath.Logger.log level "Originate Batcher contract" in
      let (_, (admin, _user1, _user2)) = Breath.Context.init_default () in
      let oracle = TestUtils.originate_oracle level in
      let initial_storage = TestStorage.initial_storage oracle.originated_address in  
      let contract = TestUtils.originate initial_storage level in

      let rate = TestUtils.create_rate_update 18724460712n None in 
      let update = Breath.Context.act_as admin (TestUtils.update_oracle oracle rate 1tez) in

      let first_tick = Breath.Context.act_as admin (TestUtils.tick "tzBTC/USDT" contract 1tez) in
      let () = Breath.Logger.log level first_tick in



      let storage = Breath.Contract.storage_of contract in
      let balance = Breath.Contract.balance_of contract in

      let oracle_storage = Breath.Contract.storage_of oracle in
      let expected_rate = TestUtils.create_rate 1872446071200n 10000000n in 

      Breath.Result.reduce [
        update
      ; first_tick
      ; Breath.Assert.is_equal "balance" balance 0tez
      ; TestStorage.Helpers.expect_oracle_value oracle_storage 18724460712n
      ; TestStorage.Helpers.expect_last_order_number storage 0n
      ; TestStorage.Helpers.expect_rate_value storage "tzBTC/USDT" expected_rate
      ]

let run_test
  (name: string)
  (description: string)
  (test_func: level -> Breath.Result.result) = Breath.Model.case name description test_func

let () =
  Breath.Model.run_suites Void [
    Breath.Model.suite "Suite for Batcher" [
      (* Contract origination tests *)
      run_test "can originate contract" "Contract can be originated with default storage" test_can_originate_contract;
      run_test "swap deposit starts batch" "A swap order deposit should start a batch" test_swap_deposit_starts_batch;
      ]
  ]

