#import "../commons/common.mligo" "Common"
#import "../commons/types.mligo" "CommonTypes"
#import "../commons/storage.mligo" "CommonStorage"
#import "../treasury/treasury.mligo" "Treasury"

type orderlist = CommonTypes.Types.swap_order list
type order = CommonTypes.Types.swap_order
type match_result = CommonTypes.Types.match_result
type orderbook = CommonStorage.Types.orderbook
type storage = CommonStorage.Types.t


let refund (_bid : order) : unit = ()

(*
    Once we get a buyer and a seller compatible for a match (same price)
    we compute the result of the match, which can be Total (the buyer want the same amount than the seller)
    or Partial (so we have to create a "remainder" order for the buyer or the seller who have amount left after the computation)
*)
let match_compute (ord1 : order) (ord2 : order) : match_result =
  let ord1NewAmount = ord1.from_amount - ord2.from_amount in
  let ord2NewAmount = ord2.from_amount - ord1.from_amount in
  if ord1NewAmount = 0 && ord2NewAmount = 0 then
    Total
  else
  if ord1NewAmount > 0 then Partial { ord1 with from_amount = (abs ord1NewAmount) }
  else
    Partial { ord2 with from_amount = (abs ord2NewAmount) }


let is_expired (order : order) : bool =
  Tezos.now >= order.deadline

(* i build the orderbook as a "price-time priority" algorithm*)
let pushOrder (order : order) (orderbook : orderbook) (from, _to : string * string) : orderbook =
  let rec acc (ods, new_ods : orderlist * orderlist) : orderlist = match ods with
      [] -> Common.Utils.list_rev (order :: new_ods)
    | h::tl ->
        if order.to_price < h.to_price then
          Common.Utils.concat (Common.Utils.list_rev ((h :: order :: new_ods))) tl
        else
        if order.to_price = h.to_price then
          if order.created_at <= h.created_at then
            Common.Utils.concat (Common.Utils.list_rev ((h :: order :: new_ods))) tl
          else
            acc (tl,(h :: new_ods))
        else
          acc (tl,(h :: new_ods))
  in
  let (new_bids,new_asks) =
    if order.swap.from.name = from then
      (acc (orderbook.bids,([] : orderlist)), orderbook.asks)
    else
      (orderbook.bids, acc (orderbook.asks,([] : orderlist)))
  in {orderbook with bids = new_bids; asks = new_asks}

(*
  orders matching according to our orderbook built as a price-time priority orderbook

  The algorithm do the matching orders/removal of expired orders during the same process in order to be more efficient
*)
let match_orders (storage : storage) : storage =
  let rec acc (bids, asks, buyers, sellers, storage : orderlist * orderlist * orderlist * orderlist * storage) : orderlist * orderlist = match bids,asks with
    | [], [] -> (buyers,sellers)
    | bid::bids, [] ->
      if is_expired bid then
        let new_storage = Treasury.Utils.redeem bid.trader bid.from_amount storage in
        acc (bids,([]:orderlist),buyers,sellers,new_storage)
      else
        acc (bids,([]:orderlist),(bid::buyers),sellers,storage)
    | [], ask :: asks ->
      if is_expired ask then
        let new_storage = Treasury.Utils.redeem ask.trader ask.from_amount storage in
        acc (([]:orderlist),asks,buyers,sellers,storage)
      else
        acc (([]:orderlist),asks,buyers,(ask :: sellers),storage)
    | bid :: bids, ask :: asks ->
      if is_expired bid then
        let new_storage = Treasury.Utils.redeem bid.trader bid.from_amount storage in
        acc (bids,(ask::asks),buyers,sellers,new_storage)
      else
        if is_expired ask then
          let new_storage = Treasury.Utils.redeem ask.trader ask.from_amount storage in
          acc (bid::bids,asks,buyers,sellers,new_storage)
        else
          if bid.to_price < ask.to_price then
            acc (bids,(ask::asks),(bid :: buyers),sellers,storage)
          else
            if bid.to_price > ask.to_price then
              acc ((bid::bids),asks,buyers,(ask :: sellers),storage)
            else
              (match (match_compute bid ask) with
              (*missing the Treasury.Utils.redeem for partial and total matching*)
              | Total -> acc (bids,asks,buyers,sellers,storage)
              | Partial new_ord ->
                  if new_ord.swap.from.name = bid.swap.from.name then
                    acc ((new_ord :: bids),asks,buyers,sellers,storage)
                  else
                    acc (bids,(new_ord :: asks),buyers,sellers,storage))
  in
  let orderbook = storage.orderbook in
  let (buyers, sellers) = acc (orderbook.bids, orderbook.asks, ([]:orderlist), ([]:orderlist), storage) in
  let new_orderbook = {orderbook with bids = Common.Utils.list_rev buyers; asks = Common.Utils.list_rev sellers} in
  {storage with orderbook = new_orderbook}

