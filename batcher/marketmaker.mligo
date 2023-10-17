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
    let () = is_administrator storage.administrator in
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
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    match Vaults.find_opt vault_name storage.vaults with
    | None ->  failwith vault_name_is_incorrect
    | Some va -> let nt = get_native_token_from_vault va in
                 if not (nt.name = vault_name) then failwith vault_name_is_incorrect else
                 let vaults = Vaults.remove vault_name storage.vaults in
                 let storage = { storage with vaults = vaults; } in
                 no_op storage

[@inline]
let tick
    (storage: storage) : result =
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


