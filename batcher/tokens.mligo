#import "constants.mligo" "Constants"
#import "errors.mligo" "Errors"
#import "../math_lib/lib/rational.mligo" "Rational"
#import "types.mligo" "Types"
#import "storage.mligo" "StorageTypes"


type valid_swaps = StorageTypes.Types.valid_swaps
type valid_tokens = StorageTypes.Types.valid_tokens
type swap = Types.Types.swap
type side = Types.Types.side
type token = Types.Types.token

module Token_Utils = struct

let are_equivalent_tokens
  (given: token)
  (test: token) : bool =
    given.name = test.name &&
    given.address = test.address &&
    given.decimals = test.decimals &&
    given.standard = test.standard

let is_valid_swap_pair
  (side: side)
  (swap: swap)
  (valid_swaps: valid_swaps): swap =
  let token_pair = Types.Utils.pair_of_swap side swap in
  let rate_name = Types.Utils.get_rate_name_from_pair token_pair in
  if Map.mem rate_name valid_swaps then swap else failwith Errors.unsupported_swap_type

let remove_token
  (token: token)
  (valid_tokens: valid_tokens) : valid_tokens =
  match Map.find_opt token.name valid_tokens with
  | Some existing_token -> if are_equivalent_tokens existing_token token then
                             Map.remove token.name valid_tokens
                           else
                             failwith Errors.token_already_exists_but_details_are_different
  | None -> valid_tokens


let add_token
  (token: token)
  (valid_tokens: valid_tokens) : valid_tokens =
  match Map.find_opt token.name valid_tokens with
  | Some existing_token -> if are_equivalent_tokens existing_token token then
                             valid_tokens
                           else
                             failwith Errors.token_already_exists_but_details_are_different
  | None -> Map.add token.name token valid_tokens

let is_token_used
  (token: token)
  (valid_swaps) : bool =
  let is_token_used_in_swap (acc, (_i, swap) : bool * (string * swap)) : bool =
    are_equivalent_tokens token swap.to ||
    are_equivalent_tokens token swap.from.token ||
    acc
  in
  Map.fold is_token_used_in_swap valid_swaps false

let add_swap
  (swap: swap)
  (valid_swaps: valid_swaps) : valid_swaps =
  let rate_name = Types.Utils.get_rate_name_from_swap swap in
  Map.add rate_name swap valid_swaps

let remove_swap
  (swap: swap)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps) : (valid_swaps * valid_tokens) =
  let rate_name = Types.Utils.get_rate_name_from_swap swap in
  let valid_swaps = Map.remove rate_name valid_swaps in
  let from = swap.from.token in
  let to = swap.to in
  let valid_tokens = if is_token_used from valid_swaps then
                       valid_tokens
                    else
                       remove_token from valid_tokens
  in
  let valid_tokens = if is_token_used to valid_swaps then
                       valid_tokens
                    else
                       remove_token to valid_tokens
  in
  (valid_swaps, valid_tokens)

end

let validate
  (side: side)
  (swap: swap)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps): swap =
  let from = swap.from.token in
  let to = swap.to in
  match Map.find_opt from.name valid_tokens with
  | None ->  failwith Errors.unsupported_swap_type
  | Some ft -> (match Map.find_opt to.name valid_tokens with
                | None -> failwith Errors.unsupported_swap_type
                | Some tt -> if (Token_Utils.are_equivalent_tokens from ft) && (Token_Utils.are_equivalent_tokens to tt) then
                              Token_Utils.is_valid_swap_pair side swap valid_swaps
                            else
                              failwith Errors.unsupported_swap_type)

let remove_pair
  (swap: swap)
  (valid_swaps: valid_swaps)
  (valid_tokens: valid_tokens) : valid_swaps * valid_tokens =
  let from = swap.from.token in
  let to = swap.to in
  let rate_name = Types.Utils.get_rate_name_from_swap swap in
  let inverse_rate_name = Types.Utils.get_inverse_rate_name_from_pair (to,from) in
  let rate_found =  Map.find_opt rate_name valid_swaps in
  let inverted_rate_found = Map.find_opt inverse_rate_name valid_swaps in
  match (rate_found, inverted_rate_found) with
  | (Some _, _) -> Token_Utils.remove_swap swap valid_tokens valid_swaps
  | (None, Some _) -> failwith Errors.inverted_swap_already_exists
  | (None, None) ->  failwith Errors.swap_does_not_exist

let add_pair
  (swap: swap)
  (valid_swaps: valid_swaps)
  (valid_tokens: valid_tokens) : valid_swaps * valid_tokens =
  let from = swap.from.token in
  let to = swap.to in
  let rate_name = Types.Utils.get_rate_name_from_swap swap in
  let inverse_rate_name = Types.Utils.get_inverse_rate_name_from_pair (to,from) in
  let rate_found =  Map.find_opt rate_name valid_swaps in
  let inverted_rate_found = Map.find_opt inverse_rate_name valid_swaps in
  match (rate_found, inverted_rate_found) with
  | (Some _, _) -> failwith Errors.swap_already_exists
  | (None, Some _) -> failwith Errors.inverted_swap_already_exists
  | (None, None) -> let valid_tokens = Token_Utils.add_token from valid_tokens in
                    let valid_tokens = Token_Utils.add_token to valid_tokens in
                    let valid_swaps = Token_Utils.add_swap swap valid_swaps in
                    (valid_swaps, valid_tokens)


