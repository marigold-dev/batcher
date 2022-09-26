#import "types.mligo" "CommonTypes"
#import "storage.mligo" "CommonStorage"
#import "errors.mligo" "PriceErrors"
#import "../math_lib/lib/float.mligo" "Float"

module Utils = struct

  type rate = CommonTypes.Types.exchange_rate

  let is_valid_rate_type (rate_name : string) (valid_swaps : CommonStorage.Types.valid_swaps) : bool =
        // match Map.find_opt rate_name valid_swaps with
        // |  None -> (failwith PriceErrors.not_a_valid_rate_pair : bool)
        // | Some (_p)  -> true
        true



  let update_current_rate (rate_name : string) (rate : CommonTypes.Types.exchange_rate) (storage : CommonStorage.Types.t) =
    let updated_rates = (match Big_map.find_opt rate_name storage.rates_current with
                          | None -> Big_map.add (rate_name) (rate) storage.rates_current
                          | Some (_p) -> Big_map.update (rate_name) (Some(rate)) (storage.rates_current)) in
    { storage with rates_current = updated_rates }
  let pow (base : int) (pow : int) : int =
    let rec iter (acc : int) (rem_pow : int) : int = (if rem_pow = 0 then acc else iter (acc * base) (rem_pow - 1)) in
    iter (1) (pow)

  let get_rate_scaling_power_of_10 (rate : rate) : Float.t =
    let from_decimals = rate.swap.from.token.decimals in
    let to_decimals = rate.swap.to.decimals in
    let diff = to_decimals - from_decimals in
    Float.new 1 diff

  let scale_on_post (rate : rate) : rate =
    let scaling_rate = get_rate_scaling_power_of_10 (rate) in
    let adjusted_rate = Float.mul rate.rate scaling_rate in
    { rate with rate = adjusted_rate }

  let scale_on_get (rate : rate) : rate =
    let scaling_rate = get_rate_scaling_power_of_10 (rate) in
    let adjusted_rate = Float.div rate.rate scaling_rate in
    { rate with rate = adjusted_rate }

end


module Rates = struct

  type storage = CommonStorage.Types.t
  type rate = CommonTypes.Types.exchange_rate
  type swap_order = CommonTypes.Types.swap_order

  let post_rate (rate : rate) (storage : storage) : storage =
    let rate_name = CommonTypes.Utils.get_rate_name(rate) in
    let scaled_rate = Utils.scale_on_post rate in
    let _ = Utils.is_valid_rate_type (rate_name) (storage.valid_swaps) in
    let s = Utils.update_current_rate (rate_name) (scaled_rate) (storage) in
    s

  let get_rate (swap: CommonTypes.Types.swap) (storage : storage) : rate =
    let rate_name =  CommonTypes.Utils.get_rate_name_from_swap swap in
    match Big_map.find_opt rate_name storage.rates_current with
      | None -> (failwith PriceErrors.no_rate_available_for_swap : rate)
      | Some r -> let scaled_rate = Utils.scale_on_get r in
                  scaled_rate

end





