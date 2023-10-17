#import "@ligo/math-lib/rational/rational.mligo" "Rational"
#include "types.mligo"
#include "utils.mligo"
#include "errors.mligo"

module TokenManager = struct 


type storage = {
    valid_tokens : ValidTokens.t;
    valid_swaps : ValidSwaps.t;
    administrator : address;
    limit_on_tokens_or_pairs : nat;
}

type result = operation list * storage

[@inline]
let confirm_swap_pair_is_disabled_prior_to_removal
  (valid_swap:valid_swap) : unit =
  if valid_swap.is_disabled_for_deposits then () else failwith cannot_remove_swap_pair_that_is_not_disabled

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
let set_deposit_status
  (pair_name: string)
  (disabled: bool)
  (storage: storage) : result =
   let () = is_known_sender storage.administrator sender_not_administrator in
   let () = reject_if_tez_supplied () in
   let valid_swap = get_valid_swap_reduced pair_name storage.valid_swaps in
   let valid_swap = { valid_swap with is_disabled_for_deposits = disabled; } in
   let valid_swaps = ValidSwaps.upsert pair_name valid_swap storage.valid_swaps in
   let storage = { storage with valid_swaps = valid_swaps; } in
   no_op (storage)

(* [@entry] *)
[@inline]
let amend_token_and_pair_limit
  (limit: nat)
  (storage: storage) : result =
  let () = is_known_sender storage.administrator sender_not_administrator in
  let () = reject_if_tez_supplied () in
  let token_count = ValidTokens.size storage.valid_tokens in
  let pair_count =  ValidSwaps.size storage.valid_swaps in
  if limit < token_count then failwith cannot_reduce_limit_on_tokens_to_less_than_already_exists else
  if limit < pair_count then failwith cannot_reduce_limit_on_swap_pairs_to_less_than_already_exists else
  let storage = { storage with limit_on_tokens_or_pairs = limit} in
  no_op (storage)

(* [@entry] *)
[@inline]
let add_token_swap_pair
  (valid_swap: valid_swap)
  (storage: storage) : result =
   let () = is_known_sender storage.administrator sender_not_administrator in
   let () = reject_if_tez_supplied () in
   if valid_swap.swap.from.token.decimals < minimum_precision then failwith swap_precision_is_less_than_minimum else
   if valid_swap.swap.to.decimals < minimum_precision then failwith swap_precision_is_less_than_minimum else
   if valid_swap.oracle_precision <> minimum_precision then failwith oracle_must_be_equal_to_minimum_precision else
   let (u_swaps,u_tokens) = Tokens.add_pair storage.limit_on_tokens_or_pairs valid_swap storage.valid_swaps storage.valid_tokens in
   let storage = { storage with valid_swaps = u_swaps; valid_tokens = u_tokens; } in
   no_op storage

(* [@entry] *)
[@inline]
let remove_token_swap_pair
  (swap: valid_swap)
  (storage: storage) : result =
   let () = is_known_sender storage.administrator sender_not_administrator in
   let () = reject_if_tez_supplied () in
   let () = confirm_swap_pair_is_disabled_prior_to_removal swap in
   let (u_swaps,u_tokens) = Tokens.remove_pair swap storage.valid_swaps storage.valid_tokens in
   let storage = { storage with valid_swaps = u_swaps; valid_tokens = u_tokens; } in
   no_op storage


(* [@entry] *)
[@inline]
let change_oracle_price_source
  (source_change: oracle_source_change)
  (storage: storage) : result =
  let () = is_known_sender storage.administrator sender_not_administrator in
  let () = reject_if_tez_supplied () in
  let valid_swap_reduced = get_valid_swap_reduced source_change.pair_name storage.valid_swaps in
  let valid_swap = { valid_swap_reduced with oracle_address = source_change.oracle_address; oracle_asset_name = source_change.oracle_asset_name; oracle_precision = source_change.oracle_precision;  } in
  let _ = get_oracle_price unable_to_get_price_from_new_oracle_source valid_swap_reduced in
  let updated_swaps = ValidSwaps.upsert source_change.pair_name valid_swap storage.valid_swaps in
  let storage = { storage with valid_swaps = updated_swaps} in
  no_op (storage)


end


[@view]
let get_valid_swaps ((), storage : unit * TokenManager.storage) : ValidSwaps.t_map = ValidSwaps.to_map storage.valid_swaps

[@view]
let get_valid_tokens ((), storage : unit * TokenManager.storage) : ValidTokens.t_map = ValidTokens.to_map storage.valid_tokens


type entrypoint =
  | Change_admin_address of address
  | Add_token_swap_pair of valid_swap
  | Remove_token_swap_pair of valid_swap
  | Amend_token_and_pair_limit of nat
  | Enable_swap_pair_for_deposit of string
  | Disable_swap_pair_for_deposit of string
  | Change_oracle_source_of_pair of oracle_source_change


let main
  (action, storage : entrypoint * TokenManager.storage) : operation list * TokenManager.storage =
  match action with
  (* Admin endpoints *)
   | Change_admin_address new_admin_address -> TokenManager.change_admin_address new_admin_address storage
   | Add_token_swap_pair valid_swap -> TokenManager.add_token_swap_pair valid_swap storage
   | Remove_token_swap_pair valid_swap -> TokenManager.remove_token_swap_pair valid_swap storage
   | Change_oracle_source_of_pair source_update -> TokenManager.change_oracle_price_source source_update storage
   | Amend_token_and_pair_limit l -> TokenManager.amend_token_and_pair_limit l storage
   | Enable_swap_pair_for_deposit pair_name -> TokenManager.set_deposit_status pair_name false storage
   | Disable_swap_pair_for_deposit pair_name -> TokenManager.set_deposit_status pair_name true storage



