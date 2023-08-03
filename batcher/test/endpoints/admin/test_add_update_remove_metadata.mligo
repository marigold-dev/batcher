#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "./../../common/helpers.mligo" "Helpers"
#import "../../../batcher.mligo" "Batcher"

let test_metadata = ("546573742044617461" : bytes)
let updated_test_metadata = ("5570646174656420546573742044617461" : bytes)

let get_metadata
   (contract: Helpers.originated_contract) 
   (key: string) = 
   let storage = Breath.Contract.storage_of contract in
   let metadata = storage.metadata in
   match Big_map.find_opt key metadata with 
   | Some m -> Some m
   | None -> None 


let change_metadata_should_succeed_if_user_is_admin =
  Breath.Model.case
  "test change metadata"
  "should be successful if user is admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let initial_metadata = get_metadata batcher "test" in 
      let act_add_metadata = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_or_update_metadata{key = "test"; value = test_metadata; } ) 0tez)) in
      
      let added_meta = get_metadata batcher "test" in

      let act_update_metadata = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_or_update_metadata{key = "test"; value = updated_test_metadata; } ) 0tez)) in
      
      let updated_meta = get_metadata batcher "test" in

      let act_remove_metadata = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Remove_metadata "test" ) 0tez)) in
      
      let removed_meta = get_metadata batcher "test" in

      Breath.Result.reduce [
        Breath.Assert.is_equal "metadata should be empty" None initial_metadata 
        ; act_add_metadata
        ; Breath.Assert.is_equal "metadata should be added" (Some test_metadata) added_meta
        ; act_update_metadata
        ; Breath.Assert.is_equal "metadata should be updated" (Some updated_test_metadata) updated_meta
        ; act_remove_metadata
        ; Breath.Assert.is_equal "metadata should be removed" None removed_meta
      ])

let change_metadata_should_fail_if_user_is_not_admin =
  Breath.Model.case
  "test change metadata"
  "should fail if user is not admin"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let initial_metadata = get_metadata batcher "test" in 
      let act_add_metadata = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_or_update_metadata{key = "test"; value = test_metadata; } ) 0tez)) in
      
      let added_meta = get_metadata batcher "test" in

      let act_update_metadata = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_or_update_metadata{key = "test"; value = updated_test_metadata; } ) 0tez)) in
      
      let updated_meta = get_metadata batcher "test" in

      let act_remove_metadata = Breath.Context.act_as context.non_admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Remove_metadata "test" ) 0tez)) in
      
      let removed_meta = get_metadata batcher "test" in

      Breath.Result.reduce [
        Breath.Assert.is_equal "metadata should be empty" None initial_metadata 
        ; Breath.Expect.fail_with_value Batcher.sender_not_administrator act_add_metadata
        ; Breath.Assert.is_equal "metadata should be empty" None added_meta
        ; Breath.Expect.fail_with_value Batcher.sender_not_administrator act_update_metadata
        ; Breath.Assert.is_equal "metadata should be empty" None updated_meta
        ; Breath.Expect.fail_with_value Batcher.sender_not_administrator act_remove_metadata
        ; Breath.Assert.is_equal "metadata should be empty" None removed_meta
      ])

let change_metadata_should_fail_if_tez_is_supplied =
  Breath.Model.case
  "test change metadata"
  "should fail if tez is supplied"
    (fun (level: Breath.Logger.level) ->
      let context = Helpers.test_context level in 
      let batcher = context.contracts.batcher in
      let initial_metadata = get_metadata batcher "test" in 
      let act_add_metadata = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_or_update_metadata{key = "test"; value = test_metadata; } ) 5tez)) in
      
      let added_meta = get_metadata batcher "test" in

      let act_update_metadata = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Add_or_update_metadata{key = "test"; value = updated_test_metadata; } ) 5tez)) in
      
      let updated_meta = get_metadata batcher "test" in

      let act_remove_metadata = Breath.Context.act_as context.admin (fun (_u:unit) -> (Breath.Contract.transfer_to batcher (Remove_metadata "test" ) 5tez)) in
      
      let removed_meta = get_metadata batcher "test" in

      Breath.Result.reduce [
        Breath.Assert.is_equal "metadata should be empty" None initial_metadata 
        ; Breath.Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_add_metadata
        ; Breath.Assert.is_equal "metadata should be empty" None added_meta
        ; Breath.Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_update_metadata
        ; Breath.Assert.is_equal "metadata should be empty" None updated_meta
        ; Breath.Expect.fail_with_value Batcher.endpoint_does_not_accept_tez act_remove_metadata
        ; Breath.Assert.is_equal "metadata should be empty" None removed_meta
      ])

let test_suite =
  Breath.Model.suite "Suite for Change MetaData (Admin)" [
    change_metadata_should_succeed_if_user_is_admin
    ; change_metadata_should_fail_if_user_is_not_admin
    ; change_metadata_should_fail_if_tez_is_supplied
  ]

