#include "../../commons/om_interface.mligo"

(*For now, the storage is only :
    - The treasury address (i need it for now as we work on separate component
    but it will be remove if we make one big contract)
    - two lists, one for the "A" token orders, and another one for the "B" token orders
*)
type storage = {
    treasury : address;
    buyers : order list;
    sellers : order list
}

let pushOrder (storage : storage) (order : order) : operation list * storage =
    match order.userType with
       Buyer -> ([],{storage with buyers = order :: storage.buyers})
     | Seller -> ([], {storage with sellers = order :: storage.sellers})

let main 
    (action, storage : entrypoints * storage) : operation list * storage =
    match action with
    | Tick -> ([], storage)
    | Ordering order -> pushOrder storage order
