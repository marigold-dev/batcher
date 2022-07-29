#import "types.mligo" "CommonTypes"


module Types struct

type valid_tokens = CommonTypes.token list

type valid_swaps =  CommonTypes.swap

type rates_current = (CommonTypes.swap, CommonTypes.exchange_rate) big_map

type rates_historic = (CommonTypes.swap, CommonTypes.exchange_rate list) big_map


end
