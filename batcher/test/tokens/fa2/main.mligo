(* Implementation for an example of TZIP-12 protocol *)

#import "errors.mligo" "Errors"

module Operators = struct
  type owner = address
  type operator = address
  type token_id = nat
  type t = ((owner * operator), token_id set) big_map

  (** If transfer policy is owner_or_operator_transfer *)
  let assert_authorisation (operators : t) (from_ : address) (token_id : nat) : unit = 
    let sender_ = Tezos.get_sender () in
    if sender_ = from_ then ()
    else 
    let authorized_tokens = 
      match Big_map.find_opt (from_, sender_) operators with
      | Some tokens -> tokens 
      | None -> Set.empty in 
    if Set.mem token_id authorized_tokens then ()
    else failwith Errors.not_operator
    
  let assert_update_permission (owner : owner) : unit =
    assert_with_error (owner = Tezos.get_sender ()) Errors.only_sender_manage_operators

  let add_operator (operators : t) (owner : owner) (operator : operator) (token_id : token_id) : t =
    if owner = operator then operators (* assert_authorisation always allow the owner so this case is not relevant *)
    else
      let () = assert_update_permission owner in
      let auth_tokens = 
        match Big_map.find_opt (owner, operator) operators with
        | Some tokens -> tokens 
        | None -> Set.empty in
      let auth_tokens  = Set.add token_id auth_tokens in
      Big_map.update (owner, operator) (Some auth_tokens) operators
         
  let remove_operator (operators : t) (owner : owner) (operator : operator) (token_id : token_id) : t =
    if owner = operator then operators (* assert_authorisation always allow the owner so this case is not relevant *)
    else
      let () = assert_update_permission owner in
      let auth_tokens = 
      match Big_map.find_opt (owner,operator) operators with
      | None -> None 
      | Some tokens ->
        let tokens = Set.remove token_id tokens in
        if Set.size tokens = 0n then None 
        else Some tokens
      in
      Big_map.update (owner, operator) auth_tokens operators
end

module Ledger = struct
  type owner = address
  type token_id = nat
  type amount_ = nat
  type t = ((owner * token_id), amount_) big_map
   
  let get_for_user (ledger : t) (owner : owner) (token_id : token_id) : amount_ =
    match Big_map.find_opt (owner,token_id) ledger with 
    | Some amount -> amount 
    | None -> 0n
   
  let set_for_user (ledger : t) (owner : owner) (token_id : token_id ) (amount_ : amount_) : t = 
    Big_map.update (owner, token_id) (Some amount_) ledger

  let decrease_token_amount_for_user (ledger : t) (from_ : owner) (token_id : nat) (amount_ : nat) : t = 
    let balance_ = get_for_user ledger from_ token_id in
    let () = assert_with_error (balance_ >= amount_) Errors.ins_balance in
    let balance_ = abs (balance_ - amount_) in
    let ledger = set_for_user ledger from_ token_id balance_ in
    ledger 

  let increase_token_amount_for_user (ledger : t) (to_ : owner) (token_id : nat) (amount_ : nat) : t = 
    let balance_ = get_for_user ledger to_ token_id in
    let balance_ = balance_ + amount_ in
    let ledger = set_for_user ledger to_ token_id balance_ in
    ledger 
end

module TokenMetadata = struct
  (*
    This should be initialized at origination, conforming to either 
    TZIP-12 : https://gitlab.com/tezos/tzip/-/blob/master/proposals/tzip-12/tzip-12.md#token-metadata
    TZIP-16 : https://gitlab.com/tezos/tzip/-/blob/master/proposals/tzip-12/tzip-12.md#contract-metadata-tzip-016 
  *)
  type data = {
    token_id : nat; 
    token_info : (string, bytes) map
  }
  type t = (nat, data) big_map 
end

module Storage = struct
  type token_id = nat
  type t = {
    ledger : Ledger.t;
    token_metadata : TokenMetadata.t;
    operators : Operators.t;
  }

  let assert_token_exist (s : t) (token_id : nat) : unit = 
    let _ = 
      Option.unopt_with_error 
      (Big_map.find_opt token_id s.token_metadata)
      Errors.undefined_token in
    ()

  let set_ledger (s : t) (ledger : Ledger.t) = { s with ledger = ledger }

  let get_operators (s : t) = s.operators

  let set_operators (s : t) (operators : Operators.t) = { s with operators = operators }
end

type storage = Storage.t

type atomic_trans = 
[@layout:comb] {
  to_  : address;
  token_id : nat;
  amount : nat;
}

type transfer_from = {
  from_ : address;
  tx : atomic_trans list
}
type transfer = transfer_from list

let transfer (t : transfer) (s : storage) : operation list * storage = 
  (* This function process the "tx" list *)
  let process_atomic_transfer (from_ : address) (ledger, t : Ledger.t * atomic_trans) =
    let { to_; token_id; amount = amount_ } = t in
    let () = Storage.assert_token_exist s token_id in
    let () = Operators.assert_authorisation s.operators from_ token_id in
    let ledger = Ledger.decrease_token_amount_for_user ledger from_ token_id amount_ in
    let ledger = Ledger.increase_token_amount_for_user ledger to_ token_id amount_ in
    ledger 
  in
  let process_single_transfer (ledger, t : Ledger.t * transfer_from) =
    let { from_ ; tx } = t in
    let ledger = List.fold_left (process_atomic_transfer from_) ledger tx in
    ledger
  in
  let ledger = List.fold_left process_single_transfer s.ledger t in
  let s = Storage.set_ledger s ledger in
  ([]: operation list), s

type request = {
  owner : address;
  token_id : nat;
}

type callback = 
[@layout:comb] {
  request : request;
  balance : nat;
}

type balance_of = 
[@layout:comb] {
  requests : request list;
  callback : callback list contract;
}

let balance_of (b : balance_of) (s : storage) : operation list * storage = 
  let { requests; callback } = b in
  let get_balance_info (request : request) : callback =
    let { owner; token_id } = request in
    let () = Storage.assert_token_exist s token_id in 
    let balance_ = Ledger.get_for_user s.ledger owner token_id in
    { request=request; balance=balance_ }
  in
  let callback_param = List.map get_balance_info requests in
  let operation = Tezos.transaction callback_param 0tez callback in
  ([operation]: operation list), s

(** update operators entrypoint *)
type operator = 
[@layout:comb] {
  owner    : address;
  operator : address;
  token_id : nat; 
}

type unit_update = 
| Add_operator of operator 
| Remove_operator of operator

type update_operators = unit_update list

let update_ops (updates : update_operators) (s : storage) : operation list * storage = 
  let update_operator (operators, update : Operators.t * unit_update) = 
    match update with 
    | Add_operator { owner=owner; operator=operator; token_id=token_id } -> 
      Operators.add_operator operators owner operator token_id
    | Remove_operator { owner=owner; operator=operator; token_id=token_id } -> 
      Operators.remove_operator operators owner operator token_id
  in
  let operators = Storage.get_operators s in
  let operators = List.fold_left update_operator operators updates in
  let s = Storage.set_operators s operators in
  ([]: operation list), s

[@view]
let get_balance ((holder, token_id), storage : (address * nat) * storage) = 
  Ledger.get_for_user storage.ledger holder token_id

type parameter = 
[@layout:comb] 
| Transfer of transfer 
| Balance_of of balance_of 
| Update_operators of update_operators

[@entry]
let main (p, s : parameter * storage) = 
  match p with
  | Transfer p -> transfer p s
  | Balance_of p -> balance_of p s
  | Update_operators p -> update_ops p s
