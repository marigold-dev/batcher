#include "../../commons/om_interface.mligo"

(*For now, the storage is only :
    - The treasury address (i need it for now as we work on separate component
    but it will be remove if we make one big contract)
    - two lists, one for the "A" token orders, and another one for the "B" token orders
*)
type storage = {
    treasury : address;
    orders : order list
}

let list_rev (l : order list) : order list =
  let rec acc (l, ll : order list * order list) : order list = match l with
   | [] -> ll
   | h::tl -> acc (tl,(h :: ll))
   in acc (l,([] : order list))


(* I keep the order list sorted by the price *)
let pushOrder (storage : storage) (order : order) : storage =
  let rec acc (ods, new_ods : order list * order list) : order list = match ods with
    | [] -> order :: new_ods
    | h::tl -> 
        if order.price <= h.price then
          acc (tl,(h :: order :: new_ods))
        else
          acc (tl,(h :: new_ods))
  in
  {storage with orders = list_rev (acc (storage.orders,([] : order list)))}

(*
    Once we get a buyer and a seller compatible for a match (same price)
    we compute the result of the match, which can be Total (the buyer want the same amount than the seller)
    or Partial (so we have to create a "remainder" order for the buyer or the seller who have amount left after the computation)
*)
let match_compute (ord1 : order) (ord2 : order) : match_result =
  let ord1NewAmount = ord1.amount - ord2.amount in
  let ord2NewAmount = ord2.amount - ord1.amount in
  if ord1NewAmount = 0 && ord2NewAmount = 0 then
    Total
  else
  if ord1NewAmount > 0 then Partial { ord1 with amount = (abs ord1NewAmount) }
  else
    Partial { ord2 with amount = (abs ord2NewAmount) }


let is_expired (order : order) : bool =
  Tezos.get_now () >= order.deadline

(* 
    a match works only for a pair (buyer,seller) or (seller,buyer) 
    and if their price are equal (no spread for now for simplicity)
    i build an new list because in ligo we have to make every recursive function, terminal.
*)        
let match_orders (storage : storage) : storage =
  let rec acc (ods, new_ods : order list * order list) : order list = match ods with
    | [] -> new_ods
    | [ord] -> if is_expired ord then new_ods else ord :: new_ods
    | ord1 :: ord2 :: tl ->
        if is_expired ord1 then 
          acc ((ord2 :: tl),new_ods)
        else
          if is_expired ord2 then
            acc ((ord1 :: tl),new_ods)
          else
            if ord1.userType <> ord2.userType && ord1.price = ord2.price then
              let res = match_compute ord1 ord2 in
              match res with 
                Total -> acc (tl,new_ods)
              | Partial new_ord -> acc ((new_ord :: tl),new_ods)
            else
              acc ((ord2 :: tl),(ord1 :: new_ods))
  in
  {storage with orders = list_rev (acc (storage.orders,([] : order list)))}

let main 
    (action, storage : entrypoints * storage) : operation list * storage =
    match action with
    | Tick -> ([], match_orders storage)
    | Ordering order -> ([],pushOrder storage order)
