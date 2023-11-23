#import "@ligo/math-lib/rational/rational.mligo" "Rational"
#include "types.mligo"
#include "utils.mligo"
#include "errors.mligo"

module MarketMaker = struct

  type storage = {
    administrator : address;
    batcher : address;
    tokenmanager : address;
    vaults: Vaults.t; 
  }

type result = operation list * storage

[@inline]
let no_op (s : storage) : result =  (([] : operation list), s)

(* [@entry] *)
[@inline]
let change_admin_address
    (new_admin_address: address)
    (storage: storage) : operation list * storage =
    let () = is_known_sender storage.administrator sender_not_administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with administrator = new_admin_address; } in
    no_op storage

(* [@entry] *)
[@inline]
let change_batcher_address
    (new_batcher_address: address)
    (storage: storage) : operation list * storage =
    let () = is_known_sender storage.administrator sender_not_administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with batcher = new_batcher_address; } in
    no_op storage

(* [@entry] *)
[@inline]
let change_tokenmanager_address
    (new_tm_address: address)
    (storage: storage) : operation list * storage =
    let () = is_known_sender storage.administrator sender_not_administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with tokenmanager = new_tm_address; } in
    no_op storage

(* [@entry] *)
[@inline]
let add_vault
    (vault_name: string)
    (vault_address: address)
    (storage: storage) : operation list * storage =
    let () = is_known_sender storage.administrator sender_not_administrator in
    let () = reject_if_tez_supplied () in
    let nt = get_native_token_from_vault vault_address in
    if not (nt.name = vault_name) then failwith vault_name_is_incorrect else
    let vaults = Vaults.upsert vault_name vault_address storage.vaults in
    let storage = { storage with vaults = vaults; } in
    no_op storage

(* [@entry] *)
[@inline]
let remove_vault
    (vault_name: string)
    (storage: storage) : operation list * storage =
    let () = is_known_sender storage.administrator sender_not_administrator in
    let () = reject_if_tez_supplied () in
    match Vaults.find_opt vault_name storage.vaults with
    | None ->  failwith vault_name_is_incorrect
    | Some va -> let nt = get_native_token_from_vault va in
                 if not (nt.name = vault_name) then failwith vault_name_is_incorrect else
                 let vaults = Vaults.remove vault_name storage.vaults in
                 let storage = { storage with vaults = vaults; } in
                 no_op storage




[@inline]
let get_volume
  (rate:exchange_rate)
  (opposing_volume: nat) : nat = 
  let rat_opposing_volume = Rational.new (int opposing_volume) in
  let rat_vol_required = Rational.mul rat_opposing_volume rate.rate in
  get_rounded_number_lower_bound rat_vol_required

[@inline]
let get_inverse_volume
  (rate:exchange_rate)
  (opposing_volume: nat) : nat = 
  let rat_opposing_volume = Rational.new (int opposing_volume) in
  let rat_vol_required = Rational.div rat_opposing_volume rate.rate in
  get_rounded_number_lower_bound rat_vol_required

[@inline]
let execute_liquidity_request
  (lt:token)
  (ot:token)
  (opposing_volume: nat)
  (vault_address:address)
  (valid_tokens:ValidTokens.t_map)
  (valid_swaps:ValidSwaps.t_map): operation = 
  let pair_name = getLexicographicalPairName lt.name ot.name in 
  match Map.find_opt pair_name valid_swaps with
  | None  -> failwith swap_does_not_exist
  | Some vs -> let (lastupdated_opt, _tes) = OracleUtils.get_oracle_price pair_name unable_to_get_price_from_oracle vs (Big_map.empty: TickErrors.t) in
               (match lastupdated_opt with
                | None -> failwith unable_to_get_price_from_oracle
                | Some (lastupdated, price) -> let swap:swap = swap_reduced_to_swap vs.swap 1n valid_tokens in
                                               let oracle_rate = OracleUtils.convert_oracle_price vs.oracle_precision swap lastupdated price valid_tokens in
                                               let (side,vol_req) = if lt.name = vs.swap.to then
                                                                      (Sell,get_inverse_volume oracle_rate opposing_volume)
                                                                    else
                                                                      (Buy,get_volume oracle_rate opposing_volume)
                                               in
                                               let req = {                      
                                                  side = side;
                                                  from_token = lt;
                                                  to_token = ot;
                                                  amount = vol_req;
                                               } in
                                               send_liquidity_injection_request req vault_address)


[@inline]
let make_liquidity_request
   (liq_token: string)
   (opposing_token: string)
   (opposing_volume: nat)
   (ops: operation list)
   (valid_tokens:ValidTokens.t_map)
   (valid_swaps:ValidSwaps.t_map)
   (vaults: Vaults.t) : operation list =
   let liq_token_opt = Map.find_opt liq_token valid_tokens in
   let opposing_token_opt = Map.find_opt opposing_token valid_tokens in
   if not (Vaults.mem liq_token vaults) then ops else
   let vault_address = Option.unopt (Vaults.find_opt liq_token vaults) in
   match (liq_token_opt,opposing_token_opt) with
   | Some lt, Some ot -> execute_liquidity_request lt ot opposing_volume vault_address valid_tokens valid_swaps :: ops
   | _,_ -> failwith token_name_not_in_list_of_valid_tokens


[@inline]
let tick
    (storage: storage) : result =
    let batches_needing_liquidity = BatcherUtils.get_batches_needing_liquidity storage.batcher in
    let vaults = storage.vaults in
    let valid_tokens = TokenManagerUtils.get_valid_tokens storage.tokenmanager in
    let valid_swaps = TokenManagerUtils.get_valid_swaps storage.tokenmanager in
    let request_liquidity ((liq_ops,batch):(operation list * batch)) : operation list =
        let (bt,st) = batch.pair in
        let buy_vol_opt = if batch.volumes.sell_total_volume = 0n then None else Some batch.volumes.sell_total_volume in
        let sell_vol_opt = if batch.volumes.buy_total_volume = 0n then None else Some batch.volumes.buy_total_volume in
        match (buy_vol_opt, sell_vol_opt) with
        | Some _,Some _ -> liq_ops
        | Some bv, None ->  make_liquidity_request st bt bv liq_ops valid_tokens valid_swaps vaults
        | None, Some sv ->  make_liquidity_request bt st sv liq_ops valid_tokens valid_swaps vaults
        | None, None -> liq_ops
   in
   let ops = List.fold_left request_liquidity ([]:operation list) batches_needing_liquidity in
   ops, storage

end

[@view]
let get_vaults ((), storage : unit * MarketMaker.storage)  = Vaults.to_map storage.vaults

type entrypoint =
  | Change_admin_address of address
  | Change_batcher_address of address
  | Change_tokenmanager_address of address
  | AddVault of string * address
  | RemoveVault of string
  | Tick

let main
  (action, storage : entrypoint * MarketMaker.storage) : operation list * MarketMaker.storage =
  match action with
  (* Market  Liquidity endpoint *)
   | AddVault (n,a)  ->  MarketMaker.add_vault n a storage
   | RemoveVault n ->  MarketMaker.remove_vault n storage
   | Tick -> MarketMaker.tick storage
  (* Admin endpoints *)
   | Change_admin_address new_admin_address -> MarketMaker.change_admin_address new_admin_address storage
   | Change_batcher_address new_batcher_address -> MarketMaker.change_batcher_address new_batcher_address storage
   | Change_tokenmanager_address new_tokenmanager_address -> MarketMaker.change_tokenmanager_address new_tokenmanager_address storage


