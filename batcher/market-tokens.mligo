#import "shared.mligo" "Shared"

type storage = {
  batcher_address: address; 
  tokens: (string,Shared.market_token) big_map;
}



[@inline]
let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
  | Mint of Shared.mint_burn_request
  | Tick of Shared.mint_burn_request


[@inline]
let mint
  (mint_request: mint_burn_request)
  (storage: storage) : result =
  no_op storage


[@view]
let getCurrentCirculation (asset, storage : string * storage) =
  match Big_map.find_opt asset storage with
  | None -> failwith "No rate available"
  | Some r -> (r.timestamp, r.value)


let main
  (action, storage : entrypoint * storage) : operation list * storage =
  match action with
    | Mint req -> mint req storage
   | Burn -> burn storage


