
type rate_update =  {
    value: nat;
    timestamp : timestamp;
  }

type storage  = rate_update option

type result = (operation list) * storage

let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
  | Update of rate_update

let update
  (update: rate_update)
  (_storage: storage) : result = 
  let storage = Some update in
  no_op storage

let main
  (action, storage : entrypoint * storage) : result =
  match action with
   | Update ru -> update ru storage


[@view]
let getPrice (_asset, storage : string * storage) =
  match storage with
  | None -> failwith "No rate available"
  | Some r -> (r.value, r.timestamp)