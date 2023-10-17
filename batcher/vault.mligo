#import "@ligo/math-lib/rational/rational.mligo" "Rational"
#include "types.mligo"
#include "utils.mligo"
#include "errors.mligo"

module Vault = struct 


type storage = {
  total_shares: nat;
  native_token: token_amount;
  foreign_tokens: token_amount_map;
  administrator : address;
  batcher : address;
  marketmaker : address;
  tokenmanager : address;
  vault_holdings: vault_holdings;
}

type result = operation list * storage

[@inline]
let no_op (s : storage) : result =  (([] : operation list), s)

[@inline]
let deposit
    (deposit_address : address)
    (deposited_token : token_amount) : operation list  =
      let treasury_vault = get_vault () in
      let deposit_op = Treasury_Utils.handle_transfer deposit_address treasury_vault deposited_token in
      [ deposit_op]

let find_liquidity_amount
  (rate:exchange_rate)
  (total_liquidity:nat)
  (volume:nat) : nat =
  let rat_volume = Rational.new (int volume) in
  let equiv_vol = Rational.mul rate.rate rat_volume in
  let resolved_equiv_vol = get_rounded_number_lower_bound equiv_vol in
  if total_liquidity > resolved_equiv_vol then resolved_equiv_vol else total_liquidity

let create_liq_order
   (bn:nat)
   (non:nat)
   (from:string)
   (to:string)
   (side:side)
   (liq:nat)
   (valid_tokens: (string,token) map): swap_order = 
   let from_token = Option.unopt (Map.find_opt from valid_tokens) in
   let to_token = Option.unopt (Map.find_opt to valid_tokens) in
   {
      order_number = non;
      batch_number = bn;
      trader = get_vault ();
      swap = {
        from = {
         token = from_token;
         amount = liq;
        };
        to = to_token;
      };
      side=side;
      tolerance = Exact;
      redeemed = false;
   }

let add_or_update_liquidity
    (holder: address)
    (token_amount: token_amount)
    (storage: storage): storage = 
    let nt = storage.native_token in 
    if not are_equivalent_tokens token_amount.token nt.token then failwith token_already_exists_but_details_are_different else
    let shares = storage.total_shares + token_amount.amount in
    let native_token = { nt with amount =  nt.amount + token_amount.amount; } in
    let new_holding = match Big_map.find_opt holder storage.vault_holdings with
                      | None -> {
                                  holder = holder;
                                  shares = token_amount.amount;
                                  unclaimed = 0mutez;
                               } 
                      | Some ph -> let nshares = ph.shares + token_amount.amount in 
                                   { ph with shares = nshares;}
    in
    let vhs = Big_map.add holder new_holding storage.vault_holdings in
    { storage with
        total_shares = shares ;
        vault_holdings = vhs;
        native_token = native_token;
    }

let collect_from_vault
    (perc_share: Rational.t)
    (ta: token_amount)
    (tam: token_amount_map): (token_amount * token_amount_map) =
    let rat_amt = Rational.new (int ta.amount) in
    let rat_amount_to_redeem = Rational.mul perc_share rat_amt in
    let amount_to_redeem = get_rounded_number_lower_bound rat_amount_to_redeem in
    if amount_to_redeem > ta.amount then failwith holding_amount_to_redeem_is_larger_than_holding else
    let rem =abs ((int ta.amount) - amount_to_redeem) in 
    let ta_rem = {ta with amount = rem; } in
    let ta_red = {ta with amount = amount_to_redeem; } in
    let tam = if ta_red.amount = 0n then  tam else TokenAmountMap.increase ta_red tam in
    (ta_rem, tam)

let collect_tokens_for_redemption
     (perc_share: Rational.t)
     (shares: nat)
     (storage: storage) = 
     let tokens = TokenAmountMap.new in 
     let (native,tokens_to_red) = collect_from_vault perc_share storage.native_token tokens in
     let acc: (Rational.t * token_amount_map * token_amount_map) = (perc_share, TokenAmountMap.new, tokens_to_red ) in
     let collect_redemptions = fun ((ps,rem_t,red_t),(_tn,ta):(Rational.t * token_amount_map * token_amount_map) * (string * token_amount)) -> 
                                let (ta_rem,red_t)  =  collect_from_vault ps ta red_t in
                                let rem_t = TokenAmountMap.increase ta_rem rem_t in
                                (ps,rem_t,red_t) 
     in
     let (_, foreign_tokens, tokens) = Map.fold collect_redemptions storage.foreign_tokens acc in
     if shares > storage.total_shares then failwith holding_shares_greater_than_total_shares_remaining else
     let rem_shares = abs (storage.total_shares - shares) in
     ({ storage with native_token = native; foreign_tokens = foreign_tokens; total_shares = rem_shares;} ,tokens)

let remove_liquidity_from_market_maker
   (holder: address)
   (storage: storage): ( operation list * storage) =
   match Big_map.find_opt holder storage.vault_holdings with 
   | None -> failwith no_holding_in_market_maker_for_holder
   | Some holding  ->  let unclaimed_tez = holding.unclaimed in
                       let shares  = holding.shares in
                       let total_shares = storage.total_shares in
                       let perc_share = Rational.div (Rational.new (int shares)) (Rational.new (int total_shares)) in
                       let (storage, tam) = collect_tokens_for_redemption perc_share shares storage in
                       let tez_op = Treasury_Utils.transfer_fee holder unclaimed_tez in
                       let treasury_vault =  get_vault () in
                       let tok_ops = Treasury_Utils.transfer_holdings treasury_vault holder tam in
                       let vault_holdings = Big_map.remove holder storage.vault_holdings in 
                       let ops: operation list =if  unclaimed_tez > 0mutez then tez_op :: tok_ops else tok_ops in 
                       let storage = { storage with vault_holdings = vault_holdings;  } in
                       (ops, storage)

let claim_from_holding
  (holding: vault_holding)
  (storage: storage) : (operation list * storage) = 
  let unclaimed_tez = holding.unclaimed in 
  if unclaimed_tez = 0mutez then failwith no_holdings_to_claim else
  let holding = { holding with unclaimed = 0tez; } in
  let tez_op = Treasury_Utils.transfer_fee holding.holder unclaimed_tez in
  let vault_holdings = Big_map.update holding.holder (Some holding) storage.vault_holdings in
  let storage = {storage with vault_holdings = vault_holdings;} in
  ([tez_op], storage)

let claim_rewards
  (holder:address)
  (storage:storage) : (operation list * storage) =
   match Big_map.find_opt holder storage.vault_holdings with
   | None -> failwith no_holdings_to_claim
   | Some h -> claim_from_holding h storage 

(* Add Liquidity into a market vault *)
[@inline]
let add_liquidity
  (amount: nat)
  (storage: storage) : result = 
  let () = reject_if_tez_supplied () in
  let holder = Tezos.get_sender () in
  let token_amount = { storage.native_token with amount = amount; } in
  let ops = deposit holder token_amount in
  let storage = add_or_update_liquidity holder token_amount storage in
  ops,storage
 

(* Add Liquidity into a market vault *)
[@inline]
let claim
  (storage: storage) : result = 
  let () = reject_if_tez_supplied () in
  let holder = Tezos.get_sender () in
  claim_rewards holder storage

(* Remove Liquidity into a market vault *)
[@inline]
let remove_liquidity
  (storage: storage) : result = 
  let () = reject_if_tez_supplied () in
  let holder = Tezos.get_sender () in
  remove_liquidity_from_market_maker holder storage

[@inline]
let change_admin_address
    (new_admin_address: address)
    (storage: storage) : result =
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with administrator = new_admin_address; } in
    no_op storage

[@inline]
let change_batcher_address
    (new_batcher_address: address)
    (storage: storage) : result =
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with batcher = new_batcher_address; } in
    no_op storage

[@inline]
let change_marketmaker_address
    (new_marketmaker_address: address)
    (storage: storage) : result =
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with marketmaker = new_marketmaker_address; } in
    no_op storage

[@inline]
let change_tokenmanager_address
    (new_tokenmanager_address: address)
    (storage: storage) : result =
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with tokenmanager = new_tokenmanager_address; } in
    no_op storage


end

[@view]
let get_native_token_of_vault ((),storage: unit * Vault.storage) : token = storage.native_token.token

(* TODO - Need to verify on-chain data for token balances prior to returning balances *)
[@view]
let get_vault_balances ((),storage: unit * Vault.storage) : (token_amount * token_amount_map) = (storage.native_token, storage.foreign_tokens)

type entrypoint =
  | AddLiquidity of nat
  | RemoveLiquidity
  | Claim
  | Change_admin_address of address
  | Change_batcher_address of address
  | Change_marketmaker_address of address
  | Change_tokenmanager_address of address

let main
  (action, storage : entrypoint * Vault.storage) : operation list * Vault.storage =
  match action with
  (* Market  Liquidity endpoint *)
   | AddLiquidity a ->  Vault.add_liquidity a storage
   | RemoveLiquidity ->  Vault.remove_liquidity storage
   | Claim  -> Vault.claim storage
  (* Admin endpoints *)
   | Change_admin_address new_admin_address -> Vault.change_admin_address new_admin_address storage
   | Change_batcher_address new_batcher_address -> Vault.change_batcher_address new_batcher_address storage
   | Change_marketmaker_address new_marketmaker_address -> Vault.change_marketmaker_address new_marketmaker_address storage
   | Change_tokenmanager_address new_tokenmanager_address -> Vault.change_tokenmanager_address new_tokenmanager_address storage


