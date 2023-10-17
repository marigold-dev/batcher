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
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with administrator = new_admin_address; } in
    no_op storage

(* [@entry] *)
[@inline]
let change_batcher_address
    (new_batcher_address: address)
    (storage: storage) : operation list * storage =
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with batcher = new_batcher_address; } in
    no_op storage

(* [@entry] *)
[@inline]
let change_tokenmanager_address
    (new_tm_address: address)
    (storage: storage) : operation list * storage =
    let () = is_administrator storage.administrator in
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
let make_liquidity_request
   (liq_token: string)
   (opposing_token: string)
   (opposing_volume: nat)
   (ops: operation list)
   (valid_tokens:ValidTokens.t_map)
   (valid_swaps:ValidSwaps.t_map)
   (vaults: Vaults.t) : operation list
   let liq_token_opt = Map.find_opt liq_token valid_tokens in
   let opposing_token_opt = Map.find_opt sell_token valid_tokens in
   match (liq_token_opt,opposing_token_opt) with
   | Some lt, Some ot -> (let pair_name = find_lexicographical_pair_name lt.name ot.name in 
                          match Map.find_opt pair_name valid_swaps with
                          | None  -> failwith swap_does_not_exist
                          | Some vs -> let (lastupdated, price) = OracleUtils.get_oracle_price unable_to_get_price_from_oracle vs in
                                       let oracle_rate = OracleUtils.convert_oracle_price valid_swap.oracle_precision valid_swap.swap lastupdated price valid_tokens in
                                       let rat_opposing_volume = Rational.new (int opposing_volume) in
                                       if lt.token.name = valid_swap.swap.to then
                                         let rat_vol_required = Rational.div rat_opposing_volume oracle_rate.rate in
                                         let vol_required = get_rounded_number_lower_bound rat_vol_required in
                                       
                                       else
                                       


    (* Create a Rational version of the  native token in the opposing vault i.e a rational version of the tzBTC held in the USDT vault   *)
    let rat_opposing_vault_native_amount = Rational.new (int opposing_vault_native_token_amount.amount) in
    (* Use the rate to create a foreign equivalent of the native token in the opposing vault  this is the tzBTC held in the USDT vault but converted into its USDT value for comparison *)
    let opposite_native_equivalent = Rational.mul rate.rate rat_opposing_vault_native_amount in 
    (* Create a Rational version of the  foreign token amount in the native vault i.e a rational version of the USDT held in the tzBTC vault   *)
    let rat_foreign_token_amount = Rational.new (int foreign_token_amount.amount) in
    (* We are comparing USDT equivalent of the tzBTC in the USDT vault with the USDT held in the tzBTC vault as a foreign token  *)
    let rat_foreign_amount_to_move = if opposite_native_equivalent > rat_foreign_token_amount then rat_foreign_token_amount else opposite_native_equivalent in
    let rat_native_amount_to_move = Rational.div rat_foreign_amount_to_move rate.rate in
    let int_native_amount_to_move = Utils.get_rounded_number_lower_bound rat_native_amount_to_move in
    let int_foreign_amount_to_move = Utils.get_rounded_number_lower_bound rat_foreign_amount_to_move in
    let native_amount_to_move = { native_token_amount with amount = int_native_amount_to_move; } in
    let foreign_amount_to_move = { foreign_token_amount with amount = int_foreign_amount_to_move; } in
     exchange_amount native_amount_to_move foreign_amount_to_move native_token_amount foreign_token_amount opposing_vault_foreign_token_amount opposing_vault_native_token_amount


   | _, _ -> failwith token_name_not_in_list_of_valid_tokens

[@inline]
let tick
    (storage: storage) : result =
    let batches_needing_liquidity = BatcherUtils.get_batches_needing_liquidity storage.batcher in
    let vaults = storage.vaults in
    let valid_tokens = TokenManagerUtils.get_valid_tokens storage.tokenmanager in
    let valid_swaps = TokenManagerUtils.get_valid_swaps storage.tokenmanager in
    let request_liquidity (liq_ops,batch):(operation list * batch) : operation list =
        let (bt,st) = batch.pair in
        let buy_vol_opt = if batch.volumes.sell_total_volume = 0n then None else Some batch.volumes.sell_total_volume in
        let sell_vol_opt = if batch.volumes.buy_total_volume = 0n then None else Some batch.volumes.buy_total_volume in
        match (buy_vol_opt, sell_vol_opt) with
        | Some _,Some _ -> liq_ops
        | Some bv, None ->  make_liquidity_request st bt bv liq_ops vaults
        | None, Some sv ->  make_liquidity_request bt st sv liq_ops vaults
        | None, None -> liq_ops

    no_op storage

end


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


