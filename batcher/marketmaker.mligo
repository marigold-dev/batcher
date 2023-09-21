#import "@ligo/math-lib/rational/rational.mligo" "Rational"
#import "types.mligo" "Types"
#import "utils.mligo" "Utils"
#import "errors.mligo" "Errors"


type token = Types.token
type side = Types.side
type token_amount = Types.token_amount
type token_amount_map = Types.token_amount_map
type market_maker_vault = Types.market_maker_vault
type market_vaults = Types.market_vaults
type market_vault_holding = Types.market_vault_holding
type valid_swaps = Types.valid_swaps
type valid_tokens = Types.valid_tokens
type exchange_rate = Types.exchange_rate
type user_holding_key = Types.user_holding_key
type user_holdings =  Types.user_holdings
type vault_holdings = Types.vault_holdings
type metadata = Types.metadata
type metadata_update = Types.metadata_update
type swap_order = Types.swap_order
type batch = Types.batch
type batch_set = Types.batch_set
type reduced_batch = Types.reduced_batch

module Storage = struct
  type t = {
    metadata: metadata;
    valid_tokens : valid_tokens;
    valid_swaps : valid_swaps;
    administrator : address;
    batcher : address;
    limit_on_tokens_or_pairs : nat;
    vaults: market_vaults; 
    last_holding_id: nat;
    user_holdings: user_holdings; 
    vault_holdings: vault_holdings;
  }
end

module MarketVaultUtils = struct

[@inline]
let deposit
    (deposit_address : address)
    (deposited_token : token_amount) : operation list  =
      let treasury_vault = Utils.get_vault () in
      let deposit_op = Utils.Treasury_Utils.handle_transfer deposit_address treasury_vault deposited_token in
      [ deposit_op]

let find_liquidity_amount
  (rate:exchange_rate)
  (total_liquidity:nat)
  (volume:nat) : nat =
  let rat_volume = Rational.new (int volume) in
  let equiv_vol = Rational.mul rate.rate rat_volume in
  let resolved_equiv_vol = Utils.get_rounded_number_lower_bound equiv_vol in
  if total_liquidity > resolved_equiv_vol then resolved_equiv_vol else total_liquidity

let create_liq_order
   (bn:nat)
   (non:nat)
   (from:string)
   (to:string)
   (side:side)
   (liq:nat)
   (valid_tokens: valid_tokens): swap_order = 
   let from_token = Option.unopt (Map.find_opt from valid_tokens) in
   let to_token = Option.unopt (Map.find_opt to valid_tokens) in
   {
      order_number = non;
      batch_number = bn;
      trader = Utils.get_vault ();
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

(*
let inject_buy_side_liquidity
  (non: nat)
  (last_rate:exchange_rate)
  (sell_volume: nat)
  (batch:batch)
  (batch_set: batch_set)
  (storage: Storage.t): batch * Storage.t =
  let (buy_token,sell_token) = batch.pair in
  match Big_map.find_opt buy_token storage.vaults with
  | None -> batch,storage
  | Some v ->  let liq_amount = find_liquidity_amount last_rate v.native_token.amount sell_volume in
               let order = create_liq_order batch.batch_number non buy_token sell_token Buy liq_amount storage.valid_tokens in
               Batch_Utils.update_storage_with_order order non batch.number batch batch_set storage

let inject_sell_side_liquidity
  (non: nat)
  (last_rate:exchange_rate)
  (buy_volume: nat)
  (batch:batch)
  (batch_set: batch_set)
  (storage: Storage.t): batch * Storage.t =
  let (buy_token, sell_token) = batch.pair in
  let mm = storage.market_maker in
  match Big_map.find_opt sell_token mm.vaults with
  | None -> batch,storage
  | Some v ->  let liq_amount = find_liquidity_amount last_rate v.native_token.amount buy_volume in
               let order = create_liq_order batch.batch_number non sell_token buy_token Sell liq_amount storage.valid_tokens in
               Batch_Utils.update_storage_with_order order non batch.number batch batch_set storage

let inject_jit_liquidity
  (last_rate:exchange_rate)
  (batch:batch)
  (next_order_number:nat)
  (storage: Storage.t): batch * Storage.t =
  let batch_set = storage.batch_set in
  let buy_volume = batch.volumes.buy_total_volume in
  let sell_volume = batch.volumes.sell_total_volume in
  if (buy_volume > 0n) && (sell_volume = 0n) then inject_sell_side_liquidity next_order_number last_rate buy_volume batch batch_set storage else
  if (buy_volume = 0n) && (sell_volume > 0n) then inject_buy_side_liquidity next_order_number last_rate sell_volume batch batch_set storage else
  batch,storage 
*)

let create_or_update_market_vault_holding
  (id: nat)
  (token_amount: token_amount)
  (holder:address)
  (previous_holding: market_vault_holding option) : market_vault_holding =
  match previous_holding with 
  | None -> {
              id = id;
              token = token_amount.token.name;
              holder = holder;
              shares = token_amount.amount;
              unclaimed = 0mutez;
             }
  | Some ph ->  if not (ph.holder = holder) then failwith Errors.incorrect_market_vault_holder else
                if not (ph.id = id) then failwith Errors.incorrect_market_vault_id else
                { ph with shares = ph.shares + token_amount.amount; }

let create_or_update_market_maker_vault
  (id: nat)
  (token_amount: token_amount)
  (mmv_opt: market_maker_vault option) : market_maker_vault = 
  match mmv_opt with
  | None  -> { 
               total_shares = token_amount.amount;
               holdings = Set.literal [ id ];
               native_token = token_amount;
               foreign_tokens = Utils.TokenAmountMap.new;
             }
  | Some mmv -> let nt = mmv.native_token in 
                if not Utils.are_equivalent_tokens token_amount.token nt.token then failwith Errors.token_already_exists_but_details_are_different else
                let shares = mmv.total_shares + token_amount.amount in
                let native_token = { nt with amount =  nt.amount + token_amount.amount; } in
                let hldgs =  if Set.mem id mmv.holdings then mmv.holdings else Set.add id mmv.holdings in  
                {
                mmv with holdings = hldgs; total_shares = shares; native_token = native_token;
                }             

let add_liquidity
    (h_key: user_holding_key)
    (new_holding_id: nat)
    (holder: address)
    (token_amount: token_amount)
    (storage: Storage.t): Storage.t = 
    let token_name = token_amount.token.name in
    let vault_opt = Big_map.find_opt token_name storage.vaults in
    let new_holding = {
      id = new_holding_id;
      token = token_amount.token.name;
      holder = holder;
      shares = token_amount.amount;
      unclaimed = 0mutez;
    } in
    let vault = create_or_update_market_maker_vault new_holding_id token_amount vault_opt in
    let vts = Big_map.update token_name (Some vault) storage.vaults in
    let uhs = Big_map.add h_key new_holding_id storage.user_holdings in
    let vhs = Big_map.add new_holding_id new_holding storage.vault_holdings in
    { storage with
        vaults = vts;
        vault_holdings = vhs;
        user_holdings = uhs;
        last_holding_id = new_holding_id;
    }


let update_liquidity
    (id: nat)
    (holder: address)
    (token_amount: token_amount)
    (storage: Storage.t): Storage.t = 
    let token_name = token_amount.token.name in
    let vault_opt = Big_map.find_opt token_name storage.vaults in
    let vault = create_or_update_market_maker_vault id token_amount vault_opt in
    let vts = Big_map.update token_name (Some vault) storage.vaults in
    let vh_opt = Big_map.find_opt id storage.vault_holdings in
    if vh_opt = (None: market_vault_holding option) then failwith Errors.unable_to_find_vault_holding_for_id else
    let vh = Option.unopt  vh_opt in
    let () = Utils.assert_or_fail_with (vh.holder = holder) Errors.user_in_holding_is_incorrect in 
    let vh = {vh with shares = vh.shares + token_amount.amount; } in 
    let vhs = Big_map.update id (Some vh) storage.vault_holdings in
    { storage with
        vaults = vts;
        vault_holdings = vhs;
        user_holdings = storage.user_holdings;
    }

let add_liquidity_to_market_maker
   (holder: address)
   (token_amount: token_amount)
   (storage: Storage.t): ( operation list * Storage.t) =
   let ops = deposit holder token_amount in
   let last_holding_id = storage.last_holding_id in 
   let next_holding_id = last_holding_id + 1n in
   let h_key = (holder, token_amount.token.name) in
   let uh_opt = Big_map.find_opt h_key storage.user_holdings in  
   let storage = match uh_opt with
            | None  -> add_liquidity h_key next_holding_id holder token_amount storage 
            | Some uh_id -> update_liquidity uh_id holder token_amount storage
   in
   (ops, storage)

let collect_from_vault
    (perc_share: Rational.t)
    (ta: token_amount)
    (tam: token_amount_map): (token_amount * token_amount_map) =
    let rat_amt = Rational.new (int ta.amount) in
    let rat_amount_to_redeem = Rational.mul perc_share rat_amt in
    let amount_to_redeem = Utils.get_rounded_number_lower_bound rat_amount_to_redeem in
    if amount_to_redeem > ta.amount then failwith Errors.holding_amount_to_redeem_is_larger_than_holding else
    let rem =abs ((int ta.amount) - amount_to_redeem) in 
    let ta_rem = {ta with amount = rem; } in
    let ta_red = {ta with amount = amount_to_redeem; } in
    let tam = if ta_red.amount = 0n then  tam else Utils.TokenAmountMap.increase ta_red tam in
    (ta_rem, tam)

let collect_tokens_for_redemption
     (holding_id: nat)
     (perc_share: Rational.t)
     (shares: nat)
     (vault: market_maker_vault) = 
     let tokens = Utils.TokenAmountMap.new in 
     let (native,tokens) = collect_from_vault perc_share vault.native_token tokens in
     let acc: (Rational.t * token_amount_map * token_amount_map) = (perc_share, Utils.TokenAmountMap.new, tokens ) in
     let collect_redemptions = fun ((ps,rem_t,red_t),(_tn,ta):(Rational.t * token_amount_map * token_amount_map) * (string * token_amount)) -> 
                                let (ta_rem,red_t)  =  collect_from_vault ps ta red_t in
                                let rem_t = Utils.TokenAmountMap.increase ta_rem rem_t in
                                (ps,rem_t,red_t) 
     in
     let (_, foreign_tokens, tokens) = Map.fold collect_redemptions vault.foreign_tokens acc in
     if shares > vault.total_shares then failwith Errors.holding_shares_greater_than_total_shares_remaining else
     let rem_shares = abs (vault.total_shares - shares) in
     let holdings = Set.remove holding_id vault.holdings in 
     ({ vault with native_token = native; foreign_tokens = foreign_tokens; holdings = holdings; total_shares = rem_shares;} ,tokens)
   
let remove_liquidity
    (id: nat)
    (holder: address)
    (token_name: string)
    (h_key: user_holding_key)
    (vault: market_maker_vault)
    (storage: Storage.t): (operation list * Storage.t) =
    let vaults = storage.vaults in
    let user_holdings = storage.user_holdings in
    let vault_holdings = storage.vault_holdings in
    let holding = Utils.find_or_fail_with id Errors.unable_to_find_vault_holding_for_id vault_holdings in 
    let  () = Utils.assert_or_fail_with (holder = holding.holder) Errors.user_in_holding_is_incorrect in
    let unclaimed_tez = holding.unclaimed in
    let shares  = holding.shares in
    let total_shares = vault.total_shares in
    let perc_share = Rational.div (Rational.new (int shares)) (Rational.new (int total_shares)) in
    let (vault, tam) = collect_tokens_for_redemption id perc_share shares vault in
    let tez_op = Utils.Treasury_Utils.transfer_fee holder unclaimed_tez in
    let treasury_vault =  Utils.get_vault () in
    let tok_ops = Utils.Treasury_Utils.transfer_holdings treasury_vault holder tam in
    let vaults = Big_map.update token_name (Some vault) vaults in
    let user_holdings = Big_map.remove h_key user_holdings in
    let vault_holdings = Big_map.remove id vault_holdings in 
    let ops: operation list =if  unclaimed_tez > 0mutez then tez_op :: tok_ops else tok_ops in 
    let storage = { storage with user_holdings = user_holdings; vault_holdings = vault_holdings; vaults = vaults; } in
    (ops, storage)

let remove_liquidity_from_market_maker
   (holder: address)
   (token_name: string)
   (storage: Storage.t): ( operation list * Storage.t) =
   let h_key = (holder, token_name) in
   let uh_opt: nat option = Big_map.find_opt h_key storage.user_holdings in  
   let v_opt = Big_map.find_opt token_name storage.vaults in 
   let () = Utils.assert_some_or_fail_with uh_opt Errors.no_holding_in_market_maker_for_holder in
   let () = Utils.assert_some_or_fail_with v_opt Errors.no_market_vault_for_token in
   remove_liquidity (Option.unopt uh_opt) holder token_name h_key (Option.unopt v_opt) storage

let claim_from_holding
  (holder:address)
  (id:nat)
  (holding: market_vault_holding)
  (storage: Storage.t) : (operation list * Storage.t) = 
  let unclaimed_tez = holding.unclaimed in 
  if unclaimed_tez = 0mutez then failwith Errors.no_holdings_to_claim else
  let holding = { holding with unclaimed = 0tez; } in
  let tez_op = Utils.Treasury_Utils.transfer_fee holder unclaimed_tez in
  let vault_holdings = Big_map.update id (Some holding) storage.vault_holdings in
  let storage = {storage with vault_holdings = vault_holdings;} in
  ([tez_op], storage)


let claim_rewards
  (holder:address)
  (token_name:string)
  (storage:Storage.t) : (operation list * Storage.t) =
   let h_key = (holder, token_name) in
   match Big_map.find_opt h_key storage.user_holdings with
   | None -> failwith Errors.no_holdings_to_claim
   | Some id -> (match Big_map.find_opt id storage.vault_holdings with
                 | None -> failwith Errors.no_holdings_to_claim
                 | Some h ->claim_from_holding holder id h storage) 

end

module BatcherUtils = struct 

[@inline]
let get_contract_entrypoint
  (entrypoint: string)
  (batcher:address) =
  match Tezos.get_entrypoint_opt entrypoint batcher with
  Some contract -> contract
  | None -> failwith Errors.entrypoint_does_not_exist

end

module TickUtils = struct


let balance_token_amounts
  (native_token_amount:token_amount)
  (foreign_token_amount:token_amount)
  (opposing_vault_foreign_token_amount:token_amount)
  (opposing_vault_native_token_amount:token_amount)
  (_valid_swaps: valid_swaps) : (token_amount * token_amount * token_amount * token_amount) = 
  (native_token_amount, foreign_token_amount, opposing_vault_foreign_token_amount, opposing_vault_native_token_amount)


[@inline]
let find_and_rebalance_foreign_vault
  (native_token_vault: market_maker_vault)
  (foreign_token_vault: market_maker_vault)
  (foreign_token_amount: token_amount)
  (valid_swaps: valid_swaps)
  (market_vaults: market_vaults ) :  (market_maker_vault * market_vaults) =
  match Map.find_opt native_token_vault.native_token.token.name foreign_token_vault.foreign_tokens with
  | None -> (native_token_vault,market_vaults)
  (* This is the native toen held as a foreign token in the foreign token vault; i.e. tzBTC held in the foreign tokens of the USDT vault *)
  | Some ovnta -> let nta = native_token_vault.native_token in  (*This is the native token of the vault that needs to be balanced i.e. tzBTC *)
                  let fta = foreign_token_amount in  (* This is the foreign token in the vault that needs toe b balanced, i.e. USDT held as a foreign token in the tzBTC vault *)
                  let ovfta = foreign_token_vault.native_token in (* This is the foreign token in the foreign  vault (but native in that vault), i.e, USDT in the USDT vault *)
                  let nta,fta,ovfta,ovnta = balance_token_amounts nta fta ovfta ovnta valid_swaps in  
                  let updated_vault_foreign_tokens = Map.update fta.token.name (Some fta) native_token_vault.foreign_tokens in 
                  let updated_vault =  { native_token_vault with native_token = nta; foreign_tokens = updated_vault_foreign_tokens;} in 
                  let opposing_vault_foreign_tokens = Map.update ovnta.token.name (Some ovnta) foreign_token_vault.foreign_tokens in
                  let updated_foreign_vault = { foreign_token_vault with native_token = ovfta; foreign_tokens = opposing_vault_foreign_tokens;  } in
                  let market_vaults  = Big_map.update updated_vault.native_token.token.name (Some updated_vault) market_vaults in
                  let market_vaults  = Big_map.update updated_foreign_vault.native_token.token.name (Some updated_foreign_vault) market_vaults in
                  (updated_vault, market_vaults)



[@inline]
let rebalance_vault
  (vault_to_balance: market_maker_vault)
  (valid_swaps: valid_swaps)
  (market_vaults: market_vaults ): market_vaults = 
  let rebalance = fun ((vtb,mvs),(foreign_token_name,foreign_token_amount):(market_maker_vault * market_vaults) * (string * token_amount)) ->
                  match  Big_map.find_opt foreign_token_name market_vaults with
                  | None ->  (vtb,mvs)
                  | Some foreign_token_vault -> find_and_rebalance_foreign_vault vault_to_balance foreign_token_vault foreign_token_amount valid_swaps market_vaults
  in
  let (_,market_vaults) = Map.fold rebalance vault_to_balance.foreign_tokens (vault_to_balance,market_vaults) in
  market_vaults



[@inline]
let rebalance_vaults
  (valid_tokens: valid_tokens)
  (_valid_swaps: valid_swaps)
  (storage: Storage.t): Storage.t = 
  let get_token_names = fun ((l,(tn,_t)):(string list * (string * token))) -> tn :: l in
  let tokens = Map.fold get_token_names valid_tokens [] in 
  let rebalance_vault = fun ((s,tn):(Storage.t * string)) -> 
                        match Big_map.find_opt tn s.vaults with
                        | Some v -> let mvaults = rebalance_vault v s.valid_swaps s.vaults in 
                                    {s with  vaults = mvaults; }
                        | None -> s
  in
  List.fold rebalance_vault tokens storage

[@inline]
let redeem
  (_batcher:address) 
  (_batches: reduced_batch list)
  (storage: Storage.t): (operation option * Storage.t) = (None: operation option), storage

[@inline]
let deposit
  (_batcher:address) 
  (_batches: reduced_batch list)
  (storage: Storage.t): (operation list * Storage.t) = ([]: operation list), storage

end

type result = operation list * Storage.t

[@inline]
let no_op (s : Storage.t) : result =  (([] : operation list), s)

type entrypoint =
  | RemoveLiquidity of string
  | AddLiquidity of token_amount
  | Claim of string
  | Tick
  | Change_admin_address of address
  | Change_batcher_address of address

(* Add Liquidity into a market vault *)
[@inline]
let add_liquidity
  (token_amount: token_amount)
  (storage: Storage.t) : result = 
  let () = Utils.reject_if_tez_supplied () in
  let holder = Tezos.get_sender () in
  MarketVaultUtils.add_liquidity_to_market_maker holder token_amount storage

(* Add Liquidity into a market vault *)
[@inline]
let claim
  (token_name: string)
  (storage: Storage.t) : result = 
  let () = Utils.reject_if_tez_supplied () in
  let holder = Tezos.get_sender () in
  MarketVaultUtils.claim_rewards holder token_name storage

(* Remove Liquidity into a market vault *)
[@inline]
let remove_liquidity
  (token_name: string)
  (storage: Storage.t) : result = 
  let () = Utils.reject_if_tez_supplied () in
  let holder = Tezos.get_sender () in
  MarketVaultUtils.remove_liquidity_from_market_maker holder token_name storage

[@inline]
let change_admin_address
    (new_admin_address: address)
    (storage: Storage.t) : result =
    let () = Utils.is_administrator storage.administrator in
    let () = Utils.reject_if_tez_supplied () in
    let storage = { storage with administrator = new_admin_address; } in
    no_op storage

[@inline]
let change_batcher_address
    (new_batcher_address: address)
    (storage: Storage.t) : result =
    let () = Utils.is_administrator storage.administrator in
    let () = Utils.reject_if_tez_supplied () in
    let storage = { storage with batcher = new_batcher_address; } in
    no_op storage

[@inline]
let get_reduced_batches
  (failure_code: nat)
  (batcher: address) : reduced_batch list =
  match Tezos.call_view "get_current_batches_reduced" () batcher with
  | Some rbl -> rbl
  | None -> failwith failure_code

[@inline]
let tick
    (storage: Storage.t) : result =
    let () = Utils.reject_if_tez_supplied () in
    let reduced_batches = get_reduced_batches Errors.unable_to_get_reduced_batches_from_batcher storage.batcher in
    let valid_tokens = storage.valid_tokens in
    let valid_swaps = storage.valid_swaps in
    let storage = TickUtils.rebalance_vaults valid_tokens valid_swaps storage in
    let (redeem_op_opt, storage) = TickUtils.redeem storage.batcher reduced_batches storage in
    let (deposit_ops, storage) = TickUtils.deposit storage.batcher reduced_batches storage in
    let ops = match redeem_op_opt with
              | Some op -> op :: deposit_ops
              | None -> deposit_ops
    in
    (ops, storage)

type vault_summary = (string, market_maker_vault) map
type holding_summary = (string, market_vault_holding) map

type  vault_holdings_summary = 
   {
     holdings: holding_summary;
     vaults: vault_summary;
   }


[@view]
let get_market_vault_holdings ((), storage : unit * Storage.t) : vault_holdings_summary =
    let vaults = storage.vaults in 
    let user_holdings = storage.user_holdings in 
    let vault_holdings = storage.vault_holdings in 
    let holder = Tezos.get_sender () in
    let get_tokens = fun (l,(tn,_vt): string list * (string * token)) -> tn :: l in
    let tokens = Map.fold get_tokens storage.valid_tokens [] in
    let get_vaults = fun (vs,t: vault_summary * string) -> 
       match Big_map.find_opt t vaults with
       | None -> vs
       | Some v -> Map.add t v vs
    in
    let vaults = List.fold get_vaults tokens (Map.empty: vault_summary) in
    let get_holdings = fun (hs,t: holding_summary * string) -> 
       let key = (holder, t) in
       match Big_map.find_opt key user_holdings with
       | None -> hs
       | Some id -> (match Big_map.find_opt id vault_holdings with
                    | None -> hs
                    | Some h -> Map.add t h hs)
    in
    let holdings = List.fold get_holdings tokens (Map.empty: holding_summary) in
    {
     holdings = holdings;
     vaults = vaults;
    }

let main
  (action, storage : entrypoint * Storage.t) : operation list * Storage.t =
  match action with
  (* Market  Liquidity endpoint *)
   | AddLiquidity t ->  add_liquidity t storage
   | RemoveLiquidity tn ->  remove_liquidity tn storage
   | Claim tn -> claim tn storage
   | Tick -> tick storage
  (* Admin endpoints *)
   | Change_admin_address new_admin_address -> change_admin_address new_admin_address storage
   | Change_batcher_address new_batcher_address -> change_batcher_address new_batcher_address storage


