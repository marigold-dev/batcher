#include "../../commons/om_interface.mligo"

(*For now, the storage is only :
    - The treasury address (i need it for now as we work on separate component
    but it will be remove if we make one big contract)
    - two lists, one for the "A" token orders, and another one for the "B" token orders
*)
type storage = {
    treasury : address;
    tokenAOrders : order list;
    tokenBOrders : order list
}

let pushOrder (storage : storage) (order : order) : operation list * storage =
    let {trader;tokenType;amount;expiry} = order in
    match tokenType with
       A -> ([],{storage with tokenAOrders = order :: storage.tokenAOrders})
     | B -> ([], {storage with tokenBOrders = order :: storage.tokenBOrders})

let main 
    (action, storage : entrypoints * storage) : operation list * storage =
    match action with
    | Tick -> ([], storage)
    | Ordering order -> pushOrder storage order
