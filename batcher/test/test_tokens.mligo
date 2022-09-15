#import "ligo-breathalyzer/lib/lib.mligo" "Breath" 
#import "../../token/main.mligo" "Token"
#import "../../token/errors.mligo" "TokenErrors"

module Utils = struct 
  type originated = Breath.Contract.originated

  (* Originate token module *)
  let originate_token (level : Breath.Logger.level) (address : address) = 
    let storage = {
      ledger = Big_map.literal [
        ((address, 0n), 1000n)
      ];
      token_metadata = Big_map.literal [
        (0n, {
          token_id = 0n;
          token_info = Map.literal [
            ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f6b69656e6c653337313939392f65633161333338616632623137366365336433656462316133653036366261662f7261772f373263666338356138303834303136633333343437333837633062613637616664666165636666622f747a4254432e6a736f6e" : bytes))
          ]
        })
      ];
      operators = (Big_map.empty : ((address * address), nat set) big_map)
    } in 
    Breath.Contract.originate level "token" Token.main storage 0tez

  (* Transfer section *)
  let transfer_token 
    (sender, receiver, token_amount : address * address * nat)
    (contract : (Token.parameter, Token.storage) originated)
    () = 
      let transfer : Token.transfer = [
        {
          from_ = sender;
          tx = [
            {
              to_ = receiver;
              token_id = 0n;
              amount = token_amount
            }
          ]
        }
      ] in 
      Breath.Contract.transfert_to contract (Transfer transfer) 0tez

  let get_token_amount (address : address) (ledger : Token.Ledger.t) : nat = 
    match Big_map.find_opt 
      (address, 0n)
      ledger
    with 
    | None -> Test.failwith TokenErrors.not_owner 
    | Some token_amount -> token_amount 

  (* Update section *)
  let update_operators
    (update : Token.unit_update) 
    (contract : (Token.parameter, Token.storage) originated)
    () = 
    let operators : Token.update_operators = [update] in 
    Breath.Contract.transfert_to contract (Update_operators operators) 0tez

  let get_list_tokens (owner : address) (operator : address) (operators : Token.Operators.t) : nat set option = 
    Big_map.find_opt (owner, operator) operators
end 

let test_transfer_tokens = 
  Breath.Model.case
  "test_transfer_tokens"
  "Trying to transfer the deployed tokens from an address to another address"
  (fun (level : Breath.Logger.level) ->
    let (_, (alice, bob, jago)) = Breath.Context.init_default () in
    let token_contract = Utils.originate_token level alice.address in 
    
    (* The sender is not included in ledger - FALSE *)
    let action1 = Breath.Context.act_as jago (Utils.transfer_token (alice.address, bob.address, 150n) token_contract) in 
    (* The sender transfers the larger tokens - FALSE *)
    let action2 = Breath.Context.act_as alice (Utils.transfer_token (alice.address, bob.address, 1500n) token_contract) in 
    (* The sender transfers the lower number - TRUE *)
    let action3 = Breath.Context.act_as alice (Utils.transfer_token (alice.address, bob.address, 150n) token_contract) in 

    let storage = Breath.Contract.storage_of token_contract in 

    Breath.Result.reduce [
      Breath.Expect.fail_with_message TokenErrors.not_operator action1;
      Breath.Expect.fail_with_message TokenErrors.ins_balance action2;
      action3;
      Breath.Assert.is_equal "remaining_alice_token" (Utils.get_token_amount alice.address storage.ledger) 850n;
      Breath.Assert.is_equal "new_bob_token" (Utils.get_token_amount bob.address storage.ledger) 150n;
    ]
  )

let test_update_operators = 
  Breath.Model.case 
  "test_update_operators"
  "Trying to update new operators for a particular owner"
  (fun (level : Breath.Logger.level) -> 
    let (_, (alice, bob, jago)) = Breath.Context.init_default () in
    let token_contract = Utils.originate_token level alice.address in 

    (* Add a new operator by a malicious owner *) 
    let action1 = 
      let operator = {
        owner = jago.address;
        operator = bob.address;
        token_id = 0n;
      } in 
      Breath.Context.act_as alice (Utils.update_operators (Add_operator operator) token_contract) in 

    (* Add a new operator by a honest owner *)
    let action2 = 
      let operator = {
        owner = alice.address;
        operator = bob.address;
        token_id = 0n;
      } in  
      Breath.Context.act_as alice (Utils.update_operators (Add_operator operator) token_contract) in 

    (* Remove the existing operator by a honest owner *)
    let action3 = 
      let operator = {
        owner = jago.address;
        operator = bob.address;
        token_id = 0n;
      } in  
      let _ = Breath.Context.act_as jago (Utils.update_operators (Add_operator operator) token_contract) in 
      Breath.Context.act_as jago (Utils.update_operators (Remove_operator operator) token_contract) in 

    let storage = Breath.Contract.storage_of token_contract in 

    Breath.Result.reduce [
      Breath.Expect.fail_with_message TokenErrors.only_sender_manage_operators action1;
      action2;
      Breath.Assert.is_some 
        "bob is the new operator of alice" 
        (Utils.get_list_tokens alice.address bob.address storage.operators);
      action3;
      Breath.Assert.is_none  
        "bob is out of the operators of jago"
        (Utils.get_list_tokens jago.address bob.address storage.operators) 
    ]
  )

let () = 
  Breath.Model.run_suites Void [
    Breath.Model.suite "Suite for Token" [
      test_transfer_tokens;
      test_update_operators
    ]
  ]