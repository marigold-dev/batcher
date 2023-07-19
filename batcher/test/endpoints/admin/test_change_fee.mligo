
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../common/helpers.mligo" "Helpers"
#import "./../../common/expect.mligo" "Expect"
#import "../../../batcher.mligo" "Batcher"


let change_fee_should_succeed_if_user_is_admin =
  Breath.Model.case
  "test change fee"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in

      let burn_address = usdt_trader.address in 
      let admin_address = eurl_trader.address in 

      let contracts = Helpers.originate_with_admin_and_burn level btc_trader usdt_trader eurl_trader admin_address burn_address in

      let batcher = contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in

      let old_fee = old_storage.fee_in_mutez in
      let new_fee = 20000mutez in
     
      let cf_ep = Change_fee new_fee in
      let act_change_fee = Breath.Context.act_as eurl_trader (fun (_u:unit) -> (Breath.Contract.transfer_to batcher cf_ep 0tez)) in

      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old fee" old_fee old_storage.fee_in_mutez
        ; act_change_fee
        ; Breath.Assert.is_equal "new fee" new_fee new_storage.fee_in_mutez
      ])

let change_fee_should_fail_if_user_is_not_admin =
  Breath.Model.case
  "test change fee"
  "should be fail if user is not admin"
    (fun (level: Breath.Logger.level) ->
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in

      let burn_address = usdt_trader.address in 
      let admin_address = eurl_trader.address in 

      let contracts = Helpers.originate_with_admin_and_burn level btc_trader usdt_trader eurl_trader admin_address burn_address in

      let batcher = contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in

      let old_fee = old_storage.fee_in_mutez in
      let new_fee = 20000mutez in
     
      let cf_ep = Change_fee new_fee in
      let act_change_fee = Breath.Context.act_as btc_trader (fun (_u:unit) -> (Breath.Contract.transfer_to batcher cf_ep 0tez)) in

      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old fee" old_fee old_storage.fee_in_mutez
        ; Expect.fail_with_value Batcher.sender_not_administrator act_change_fee
        ; Breath.Assert.is_equal "old fee is unchanged" old_fee new_storage.fee_in_mutez
      ])

let change_fee_should_fail_if_tez_is_sent =
  Breath.Model.case
  "test change fee"
  "should fail if tez is sent"
    (fun (level: Breath.Logger.level) ->
      let (_, (btc_trader, usdt_trader, eurl_trader)) = Breath.Context.init_default () in

      let burn_address = usdt_trader.address in 
      let admin_address = eurl_trader.address in 

      let contracts = Helpers.originate_with_admin_and_burn level btc_trader usdt_trader eurl_trader admin_address burn_address in

      let batcher = contracts.batcher in
      let old_storage = Breath.Contract.storage_of batcher in

      let old_fee = old_storage.fee_in_mutez in
      let new_fee = 20000mutez in
     
      let cf_ep = Change_fee new_fee in
      let act_change_fee = Breath.Context.act_as eurl_trader (fun (_u:unit) -> (Breath.Contract.transfer_to batcher cf_ep 5tez)) in

      let new_storage = Breath.Contract.storage_of batcher in

      Breath.Result.reduce [
        Breath.Assert.is_equal "old fee" old_fee old_storage.fee_in_mutez
        ; Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_change_fee
        ; Breath.Assert.is_equal "old fee is unchanged" old_fee new_storage.fee_in_mutez
      ])
let test_suite =
  Breath.Model.suite "Suite for Deposits" [
    change_fee_should_succeed_if_user_is_admin
    ; change_fee_should_fail_if_user_is_not_admin
    ; change_fee_should_fail_if_tez_is_sent
  ]

