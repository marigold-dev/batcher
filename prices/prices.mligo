#import "../commons/types.mligo" "CommonTypes"
#import "../commons/storage.mligo" "CommonStorage"
#import "errors.mligo" "PriceErrors"

module Utils = struct
  let is_valid_rate_type (rate_name : string) (valid_swaps : CommonStorage.Types.valid_swaps) : bool =
        match Map.find_opt rate_name valid_swaps with
        |  None -> (failwith PriceErrors.not_a_valid_rate_pair : bool)
        | Some (_p)  -> true


  let add_rate_to_historic_prices (rate_name : string) (current_rate : CommonTypes.Types.exchange_rate) (historic : CommonStorage.Types.rates_historic) =
    match Big_map.find_opt rate_name historic with
         | None ->  current_rate :: []
         | Some (rts) -> current_rate ::rts


  let archive_rate (rate_name : string) (storage : CommonStorage.Types.t) : CommonStorage.Types.t =
    let updated_archive_rates  = (match Big_map.find_opt rate_name storage.rates_current with
                                                                         | None -> storage.rates_historic
                                                                         | Some(cp) ->
                                                                              let updated : CommonTypes.Types.exchange_rate list  = add_rate_to_historic_prices (rate_name) (cp) (storage.rates_historic) in
                                                                              Big_map.update (rate_name) (Some(updated)) (storage.rates_historic)
                                                                              ) in
    { storage with rates_historic = updated_archive_rates  }

  let update_current_rate (rate_name : string) (rate : CommonTypes.Types.exchange_rate) (storage : CommonStorage.Types.t) =
    let updated_rates = (match Big_map.find_opt rate_name storage.rates_current with
                          | None -> Big_map.add (rate_name) (rate) storage.rates_current
                          | Some (_p) -> Big_map.update (rate_name) (Some(rate)) (storage.rates_current)) in
    { storage with rates_current = updated_rates }

end


module Rates = struct

  let post_rate (rate : CommonTypes.Types.exchange_rate) (storage : CommonStorage.Types.t) : CommonStorage.Types.t =
    let rate_name = CommonTypes.Utils.get_rate_name(rate) in
    let _ = Utils.is_valid_rate_type (rate_name) (storage.valid_swaps) in
    let s = Utils.archive_rate (rate_name) (storage) in
    let s = Utils.update_current_rate (rate_name) (rate) (s) in
    s


end





