
module Oracle = struct

type rate_update =  {
    name: string;
    value: nat;
    timestamp : timestamp;
  }

type storage  = (string, rate_update) map

type result = (operation list) * storage

let no_op (s : storage) : result =  (([] : operation list), s)

let update
  (update: rate_update)
  (storage: storage) : result =
  let storage = match Map.find_opt update.name storage with
                | None -> Map.add update.name update storage
                | Some _ -> Map.update update.name (Some update) storage
  in
  no_op storage

end


type entrypoint =
  | Update of Oracle.rate_update

[@entry]
let main
  (action, storage : entrypoint * Oracle.storage) : Oracle.result =
  match action with
   | Update ru -> Oracle.update ru storage


[@view]
let getPrice (asset, storage : string * Oracle.storage) =
  match Map.find_opt asset storage with
  | None -> failwith "No rate available"
  | Some r -> (r.timestamp, r.value)

