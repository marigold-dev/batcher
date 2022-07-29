#include "../../commons/om_interface.mligo"

(*For now, the storage is only :
    - The treasury address (i need it for now as we work on separate component
    but it will be remove if we make one big contract)
    - two lists, one for the "A" token orders, and another one for the "B" token orders
*)
type storage = {
    treasury : address;
    bids : order list;
    asks : order list
}

let list_rev (l : order list) : order list =
  let rec acc (l, ll : order list * order list) : order list = match l with
   | [] -> ll
   | h::tl -> acc (tl,(h :: ll))
   in acc (l,([] : order list))

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

(* i build the orderbook as a "price-time priority" algorithm*)
let pushOrder (order : order) (storage : storage)  : storage=
  let rec acc (ods, new_ods : order list * order list) : order list = match ods with
      [] -> [order]
    | h::tl -> 
        if order.price < h.price then
          acc (tl,(order :: h :: new_ods))
        else
        if order.price = h.price then
          if order.created_at <= h.created_at then
            acc (tl,(order :: h :: new_ods))
          else
            acc (tl,(h :: order :: new_ods))
        else
          acc (tl,(h :: new_ods))
  in
  let (new_bids,new_asks) = 
    if order.side = Buy then 
      (list_rev (acc (storage.bids,([] : order list))), storage.asks)
    else 
      (storage.bids, list_rev (acc (storage.asks,([] : order list))))
  in {storage with bids = new_bids; asks = new_asks}

(* 
  orders matching according to our orderbook built as a price-time priority orderbook 

  The algorithm do the matching orders/removal of expired orders during the same process in order to be more efficient
*)
let match_orders (storage : storage) =
  let rec acc (bids, asks, buyers, sellers : order list * order list * order list * order list) : order list * order list = match bids,asks with
    | [], [] -> (buyers,sellers)
    | h::tl, [] -> if is_expired h then acc (tl,asks,buyers,sellers) else acc (tl,asks,(h::buyers),sellers)
    | [], h :: tl -> if is_expired h then acc (tl,asks,buyers,sellers) else acc (bids,tl,buyers,(h :: sellers))
    | bid :: bids, ask :: asks ->
      if is_expired bid then 
        acc (bids,(ask::asks),buyers,sellers)
      else
        if is_expired ask then
          acc (bid::bids,asks,buyers,sellers)
        else
          if bid.price < ask.price then
            acc (bids,(ask::asks),(bid :: buyers),sellers)
          else
            if bid.price > ask.price then
              acc ((bid::bids),asks,buyers,(ask :: sellers))
            else
              (match (match_compute bid ask) with
              | Total -> acc (bids,asks,buyers,sellers)
              | Partial new_ord ->
                  if new_ord.side = Buy then 
                    acc ((new_ord :: bids),asks,buyers,sellers)
                  else
                    acc (bids,(new_ord :: asks),buyers,sellers))
  in
  let (buyers, sellers) = acc (storage.bids, storage.asks, ([]:order list), ([]:order list)) in
  {storage with bids = list_rev buyers; asks = list_rev sellers}

let main 
    (action, storage : entrypoints * storage) : operation list * storage =
    match action with
    | Tick -> ([], match_orders storage)
    | Ordering order -> ([],pushOrder order storage)
