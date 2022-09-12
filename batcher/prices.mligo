#import "types.mligo" "CommonTypes"
#import "storage.mligo" "CommonStorage"
#import "errors.mligo" "PriceErrors"

module Utils = struct
  let is_valid_rate_type (rate_name : string) (valid_swaps : CommonStorage.Types.valid_swaps) : bool =
        match Map.find_opt rate_name valid_swaps with
        |  None -> (failwith PriceErrors.not_a_valid_rate_pair : bool)
        | Some (_p)  -> true


  let update_current_rate (rate_name : string) (rate : CommonTypes.Types.exchange_rate) (storage : CommonStorage.Types.t) =
    let updated_rates = (match Big_map.find_opt rate_name storage.rates_current with
                          | None -> Big_map.add (rate_name) (rate) storage.rates_current
                          | Some (_p) -> Big_map.update (rate_name) (Some(rate)) (storage.rates_current)) in
    { storage with rates_current = updated_rates }

end


module Rates = struct

  type storage = CommonStorage.Types.t
  type rate = CommonTypes.Types.exchange_rate
  type swap_order = CommonTypes.Types.swap_order

  let post_rate (rate : rate) (storage : storage) : storage =
    let rate_name = CommonTypes.Utils.get_rate_name(rate) in
    let _ = Utils.is_valid_rate_type (rate_name) (storage.valid_swaps) in
    let s = Utils.update_current_rate (rate_name) (rate) (storage) in
    s

  let get_rate (swap: CommonTypes.Types.swap) (storage : storage) : rate =
    let rate_name =  CommonTypes.Utils.get_rate_name_from_swap swap in
    match Big_map.find_opt rate_name storage.rates_current with
      | None -> (failwith PriceErrors.no_rate_available_for_swap : rate)
      | Some r -> r

end





