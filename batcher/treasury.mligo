#import "types.mligo" "Types"
#import "storage.mligo" "Storage"
#import "errors.mligo" "Errors"
#import "batch.mligo" "Batch"

type storage = Storage.Types.t
type treasury = Types.Types.treasury
type token_amount = Types.Types.token_amount
type token = Types.Types.token
type treasury_holding = Types.Types.treasury_holding
type token_holding = Types.Types.token_holding

module Utils = struct
  type adjustment = INCREASE | DECREASE

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

  (* Transferred format for tokens in FA2 standard *)
  type transfer = transfer_from list


  (* Transfer the tokens to the appropriate address. This is based on the FA2 token standard *)
  let transfer_token
    (sender : address)
    (receiver : address)
    (token_address : address)
    (token_amount : nat) : operation =
      let transfer_entrypoint : transfer contract =
        match (Tezos.get_entrypoint_opt "%transfer" token_address : transfer contract option) with
        | None -> failwith Errors.invalid_token_address
        | Some transfer_entrypoint -> transfer_entrypoint
      in
      let transfer : transfer = [
        {
          from_ = sender;
          tx = [
            {
              to_ = receiver;
              token_id = 0n; // Need more discussion to decide to whether have token_id parameter or not
              amount = token_amount
            }
          ]
        }
      ] in
      Tezos.transaction transfer 0tez transfer_entrypoint
  (* Transfer the XTZ to the appropriate address *)
  let transfer_xtz (receiver : address) (amount : tez) : operation =
    let received_contract : unit contract =
      match (Tezos.get_contract_opt receiver : unit contract option) with
      | None -> failwith Errors.invalid_tezos_address
      | Some address -> address in
    Tezos.transaction () amount received_contract

  let handle_transfer (sender : address) (receiver : address) (received_token : token_amount) : operation =
    match received_token.token.address with
    | None ->
      let xtz_amount = received_token.amount * 1tez in
      transfer_xtz receiver xtz_amount
    | Some token_address ->
      transfer_token sender receiver token_address received_token.amount


  let token_amount_to_token_holding
    (holder : address)
    (token_amount : token_amount) : token_holding =
    {
      holder =  holder;
      token_amount = token_amount;
    }


  let adjust_token_holding
    (th : token_holding)
    (adjustment : adjustment)
    (adjustment_holding : token_holding) : token_holding =
      let original_token_amount = th.token_amount in
      let adjustment_token_amount = Types.Utils.check_token_equality original_token_amount adjustment_holding.token_amount in
      let original_balance = original_token_amount.amount in
      let adjustment_balance = adjustment_token_amount.amount in
      let new_balance = (match adjustment with
                         | INCREASE -> original_balance + adjustment_balance
                         | DECREASE -> abs (original_balance - adjustment_balance)
                         ) in
      let new_token_amount = { original_token_amount with amount = new_balance  } in
      { th with token_amount = new_token_amount }

  let adjust_treasury_holding
    (assigned_token_holder : address)
    (adjustment : adjustment)
    (token_holding : token_holding)
    (treasury_holding : treasury_holding) : treasury_holding =
    let token_name = Types.Utils.get_token_name_from_token_holding token_holding in
    let existing_token_holding_opt = Map.find_opt token_name treasury_holding in
    match adjustment with
    | DECREASE -> (match existing_token_holding_opt with
                   | None -> (failwith Errors.insufficient_token_holding_for_decrease : treasury_holding)
                   | Some (th) -> let new_holding = adjust_token_holding th DECREASE token_holding in
                                  Map.update (token_name) (Some(new_holding)) treasury_holding)
    | INCREASE -> (match existing_token_holding_opt with
                   | None -> let new_holding = Types.Utils.assign_new_holder_to_token_holding assigned_token_holder token_holding in
                             Map.add (token_name) (new_holding) (treasury_holding)
                   | Some (th) -> let new_holding = adjust_token_holding th INCREASE token_holding in
                                  Map.update (token_name) (Some(new_holding)) (treasury_holding))

  let atomic_swap
    (this_token_holding : token_holding)
    (this_treasury_holding : treasury_holding)
    (with_that_token_holding : token_holding)
    (with_that_treasury_holding : treasury_holding)
    (treasury : treasury) : treasury =
    let this_holder_address = this_token_holding.holder in
    let with_that_holder_address = with_that_token_holding.holder in
    let this_h = adjust_treasury_holding this_holder_address DECREASE this_token_holding this_treasury_holding in
    let that_h = adjust_treasury_holding with_that_holder_address DECREASE with_that_token_holding with_that_treasury_holding in
    let this_h = adjust_treasury_holding this_holder_address INCREASE with_that_token_holding this_treasury_holding in
    let that_h = adjust_treasury_holding with_that_holder_address INCREASE this_token_holding with_that_treasury_holding in
    let t = Big_map.update (this_holder_address) (Some(this_h)) treasury in
    let t = Big_map.update (with_that_holder_address) (Some(that_h)) treasury in
    treasury

  (* Deposit tokens into storage *)
  let deposit_treasury (address : address) (received_token : token_amount) (treasury : treasury) : treasury =
    let token_name = Types.Utils.get_token_name_from_token_amount received_token in
    let token_holding = token_amount_to_token_holding address received_token in
    let new_treasury_holding = (match Big_map.find_opt address treasury with
                                | None -> Map.literal [ (token_name, Some (token_holding) )]
                                | Some (treasury_holding) ->  (match Map.find_opt token_name treasury_holding with
                                                               | None -> Map.add (token_name) (token_holding) (treasury_holding)
                                                               | Some (oth) -> let new_token_holding = adjust_token_holding oth INCREASE token_holding in
                                                                               Map.update (token_name) (Some(new_token_holding)) (treasury_holding)
                                                               )) in
    Big_map.update address Some (treasury_holding) treasury


  (* FIXME:  This needs to be more robust for cases where one token in a two token holding fails *)
  let redeem_all_tokens_from_treasury_holding
    (holder : address)
    (th : treasury_holding) =
    let transfer_token_holding (tkh) =
      (let _ = Utils.handle_transfer treasury_vault redeem_address redeemed_token in
      ()) in
    Map.iter transfer_token_holding th

  let redeem_holdings_from_single_batch
    (holder : address)
    (batch : Batch.t ) : Batch.t =
    match batch.status with
    | Cleared -> (match Big_map.find_opt holder batch.treasury with
                  | Some (th) -> let _ = redeem_all_tokens_from_treasury_holding holder th in
                                let updated_treasury = Big_map.delete holder in
                                { batch with treasury =updated_treasury }
                  | None -> batch)
    | Open -> batch
    | Closed  -> batch


  let redeem_holdings_from_batches
    (holder : address)
    (batches : batch_set ) : batch_set =
    let updated_previous = List.map (redeem_holdings_from_batches (holder)) batches.previous in
    { batches with previous = updated_previous }

      (* let treasury = Utils.redeem_treasury deposit_address redeemed_token treasury_vault storage.treasury in *)

end


let treasury_vault : address = Tezos.self_address


let deposit
    (deposit_address : address)
    (deposited_token : token_amount)
    (storage : storage) : storage =
      let treasury = Utils.deposit_treasury deposit_address deposited_token storage.treasury in
      let _ = Utils.handle_transfer deposit_address treasury_vault deposited_token in
      { storage with treasury = treasury }

let redeem
    (redeem_address : address)
    (storage : storage) : storage =
      let updated_batches = redeem_holdings_from_batches storage.batches in
      { storage with batches = updated_batches }

let swap
    (this : token_holding)
    (with_that : token_holding)
    (treasury : treasury) : treasury =
    let this_holding = Utils.has_sufficient_holding this treasury in
    let that_holding = Utils.has_sufficient_holding with_that treasury in
    match Utils.atomic_swap this_holding that_holding treasury with
    | Some (t) -> t
    | None -> treasury
