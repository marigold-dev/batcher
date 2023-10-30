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
  vault_holdings: VaultHoldings.t;
}

type result = operation list * storage

[@inline]
let no_op (s : storage) : result =  (([] : operation list), s)


[@inline]
let assert_balances
  (storage:storage) : operation list = 
  let vault_address = Tezos.get_self_address () in
  let nta = storage.native_token in
  let nt = nta.token in
  let ft = storage.foreign_tokens in
  let ntop = gettokenbalance vault_address vault_address nt.token_id nt.address nt.standard in
  let trigger_balance_update (ops,(_name,ta): (operation list * (string * token_amount))) :  operation list = 
      (gettokenbalance vault_address vault_address ta.token.token_id ta.token.address ta.token.standard) :: ops
  in
  Map.fold trigger_balance_update ft [ ntop ]




[@inline]
let deposit
    (deposit_address : address)
    (deposited_token : token_amount)
    (_storage:storage): operation list  =
      let treasury_vault = get_vault () in
      let deposit_op = Treasury_Utils.handle_transfer deposit_address treasury_vault deposited_token in
      (* let bal_ops = assert_balances storage in 
      deposit_op :: bal_ops *)
      [ deposit_op ]

[@inline]
let find_liquidity_amount
  (rate:exchange_rate)
  (total_liquidity:nat)
  (volume:nat) : nat =
  let rat_volume = Rational.new (int volume) in
  let equiv_vol = Rational.mul rate.rate rat_volume in
  let resolved_equiv_vol = get_rounded_number_lower_bound equiv_vol in
  if total_liquidity > resolved_equiv_vol then resolved_equiv_vol else total_liquidity

[@inline]
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

[@inline]
let add_or_update_liquidity
    (holder: address)
    (token_amount: token_amount)
    (storage: storage): storage = 
    let nt = storage.native_token in 
    if not are_equivalent_tokens token_amount.token nt.token then failwith token_already_exists_but_details_are_different else
    let shares = storage.total_shares + token_amount.amount in
    let native_token = { nt with amount =  nt.amount + token_amount.amount; } in
    let new_holding = match VaultHoldings.find_opt holder storage.vault_holdings with
                      | None -> {
                                  holder = holder;
                                  shares = token_amount.amount;
                                  unclaimed = 0mutez;
                               } 
                      | Some ph -> let nshares = ph.shares + token_amount.amount in 
                                   { ph with shares = nshares;}
    in
    let vhs = VaultHoldings.upsert holder new_holding storage.vault_holdings in
    { storage with
        total_shares = shares ;
        vault_holdings = vhs;
        native_token = native_token;
    }

[@inline]
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

[@inline]
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

[@inline]
let remove_liquidity_from_market_maker
   (holder: address)
   (storage: storage): ( operation list * storage) =
   match VaultHoldings.find_opt holder storage.vault_holdings with 
   | None -> failwith no_holding_in_market_maker_for_holder
   | Some holding  ->  let unclaimed_tez = holding.unclaimed in
                       let shares  = holding.shares in
                       let total_shares = storage.total_shares in
                       let perc_share = Rational.div (Rational.new (int shares)) (Rational.new (int total_shares)) in
                       let (storage, tam) = collect_tokens_for_redemption perc_share shares storage in
                       let tez_op = Treasury_Utils.transfer_fee holder unclaimed_tez in
                       let treasury_vault =  get_vault () in
                       let tok_ops = Treasury_Utils.transfer_holdings treasury_vault holder tam in
                       let vault_holdings = VaultHoldings.remove holder storage.vault_holdings in 
                       (* let bal_ops = assert_balances storage in *)
                       let ops: operation list =if  unclaimed_tez > 0mutez then tez_op :: tok_ops else tok_ops in 
                       (* let ops =  concatlo trans_ops bal_ops in  *)
                       let storage = { storage with vault_holdings = vault_holdings;  } in
                       (ops, storage)

[@inline]
let claim_from_holding
  (holding: vault_holding)
  (storage: storage) : (operation list * storage) = 
  let unclaimed_tez = holding.unclaimed in 
  if unclaimed_tez = 0mutez then failwith no_holdings_to_claim else
  let holding = { holding with unclaimed = 0tez; } in
  let tez_op = Treasury_Utils.transfer_fee holding.holder unclaimed_tez in
  let vault_holdings = VaultHoldings.upsert holding.holder holding storage.vault_holdings in
  let storage = {storage with vault_holdings = vault_holdings;} in
  ([tez_op], storage)

let claim_rewards
  (holder:address)
  (storage:storage) : (operation list * storage) =
   match VaultHoldings.find_opt holder storage.vault_holdings with
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
  let ops = deposit holder token_amount storage in
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
    let () = is_known_sender storage.administrator sender_not_administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with administrator = new_admin_address; } in
    no_op storage

[@inline]
let change_batcher_address
    (new_batcher_address: address)
    (storage: storage) : result =
    let () = is_known_sender storage.administrator sender_not_administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with batcher = new_batcher_address; } in
    no_op storage

[@inline]
let construct_order
  (side:side)
  (from_token:token)
  (to_token:token)
  (amount:nat) : external_swap_order = 
  let side_nat = side_to_nat side in
  let tolerance = tolerance_to_nat Exact in 
  let swap = {
    from= {
          token = from_token;
          amount= amount
          };
    to = to_token;
  } in
  {
  swap = swap;
  created_at = Tezos.get_now ();
  side = side_nat;
  tolerance = tolerance;
  }

[@inline]
let inject_liquidity
    (lir: liquidity_injection_request)
    (storage: storage) : result =
    let () = is_known_sender storage.marketmaker sender_not_marketmaker in
    let () = reject_if_tez_supplied () in
    let o = construct_order lir.side lir.from_token lir.to_token lir.amount in
    let dep_ops = execute_deposit o storage.batcher in
    let bal_ops = assert_balances storage in
    let ops = concatlo dep_ops bal_ops in
    ops, storage

[@inline]
let add_reward
    (reward: tez)
    (storage: storage) : result =
    let rat_total_shares = Rational.new (int storage.total_shares) in
    let int_tez_reward: int = int (reward / 1mutez) in
    let rat_tez_reward = Rational.new int_tez_reward in
    let add_rewards = fun (holdings,(addr,holding):VaultHoldings.t * (VaultHoldings.key * VaultHoldings.value)) -> 
                      let rat_shares = Rational.new (int holding.shares) in
                      let perc_share = Rational.div rat_shares rat_total_shares in
                      let rew_to_user = Rational.mul perc_share rat_tez_reward in 
                      let rew_to_user_in_tez = 1mutez * (get_rounded_number_lower_bound rew_to_user) in
                      let updated_rewards =if rew_to_user_in_tez > 0mutez then holding.unclaimed + rew_to_user_in_tez else holding.unclaimed in
                      let new_holding = { holding with unclaimed = updated_rewards; } in
                      VaultHoldings.upsert addr new_holding holdings
    in
    let vault_holdings = VaultHoldings.fold add_rewards storage.vault_holdings VaultHoldings.empty in
    let storage = { storage with  vault_holdings=vault_holdings; } in
    no_op storage


[@inline]
let change_marketmaker_address
    (new_marketmaker_address: address)
    (storage: storage) : result =
    let () = is_known_sender storage.administrator sender_not_administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with marketmaker = new_marketmaker_address; } in
    no_op storage

[@inline]
let change_tokenmanager_address
    (new_tokenmanager_address: address)
    (storage: storage) : result =
    let () = is_known_sender storage.administrator sender_not_administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with tokenmanager = new_tokenmanager_address; } in
    no_op storage

[@inline]
let update_native_token_balance
  (token_address: address)
  (amount:nat)
  (token_id: nat)
  (storage:storage): storage = 
  let nta = assert_some_or_fail_with storage.native_token.token.address invalid_token_address in
  if nta = token_address && storage.native_token.token.token_id = token_id then
    let nt = { storage.native_token with amount=amount;} in
    { storage with native_token = nt;}
  else
    storage

[@inline]
let update_foreign_token_balances
  (token_address: address)
  (amount:nat)
  (token_id: nat)
  (storage:storage): storage =
  let fts = storage.foreign_tokens in
  let update_bals (fts, (_name,ta): token_amount_map * (string * token_amount)) : token_amount_map =
     let ta_addr = assert_some_or_fail_with ta.token.address invalid_token_address in
     if ta_addr = token_address &&  ta.token.token_id = token_id then
       let ta = {ta with amount = amount;} in
       Map.update ta.token.name (Some ta) fts
     else
       fts
  in
  let fts = Map.fold update_bals fts fts in 
  { storage with foreign_tokens = fts; }
 
[@inline]
let process_balance_response_fa12
  (amount: nat)
  (storage:storage): result = 
  let token_contract = Tezos.get_sender () in
  let storage = update_native_token_balance token_contract amount 0n storage in
  let storage = update_foreign_token_balances token_contract amount 0n storage in
  no_op storage

[@inline]
let process_balance_response_fa2
  (rs: balance_of_response list)
  (storage:storage): result = 
  let token_contract = Tezos.get_sender () in
  let process_responses (s,r:storage * balance_of_response):storage = 
    let amount = r.balance in
    let token_id = r.request.token_id in
    let s = update_native_token_balance token_contract amount token_id s in
    update_foreign_token_balances token_contract amount token_id s in
  let storage = List.fold process_responses rs storage in
  no_op storage

end

[@view]
let get_native_token_of_vault ((),storage: unit * Vault.storage) : token = storage.native_token.token

[@view]
let check_entrypoints ((fa2token,fa12token),_storage: (address * address) * Vault.storage) : bool * bool * bool * bool =
  let vault_address = Tezos.get_self_address () in
  entrypoints_exist vault_address fa12token fa2token



type entrypoint =
  | AddLiquidity of nat
  | RemoveLiquidity
  | Claim
  | AddReward of tez
  | InjectLiquidity of liquidity_injection_request
  | AssertBalances
  | Balance_response_fa2 of balance_of_responses
  | Balance_response_fa12 of nat
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
  (* Batcher endpoints *)
   | AddReward r ->  Vault.add_reward r storage
  (* MarketMaker endpoints *)
   | InjectLiquidity lir ->  Vault.inject_liquidity lir storage
  (* Balance endpoints *)
   | AssertBalances -> (Vault.assert_balances storage, storage)
   | Balance_response_fa2 r -> Vault.process_balance_response_fa2 r storage
   | Balance_response_fa12 r -> Vault.process_balance_response_fa12 r storage
  (* Admin endpoints *)
   | Change_admin_address new_admin_address -> Vault.change_admin_address new_admin_address storage
   | Change_batcher_address new_batcher_address -> Vault.change_batcher_address new_batcher_address storage
   | Change_marketmaker_address new_marketmaker_address -> Vault.change_marketmaker_address new_marketmaker_address storage
   | Change_tokenmanager_address new_tokenmanager_address -> Vault.change_tokenmanager_address new_tokenmanager_address storage


