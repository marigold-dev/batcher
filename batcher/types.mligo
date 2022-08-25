module Types = struct

  (* Associate alias to token address *)
  type token = {
    [@layout:comb]
    name : string;
    address : address option;
  }

  (* Side of an order, either BUY side or SELL side  *)
  type side = BUY | SELL

  (* Tolerance of the order against the oracle price  *)
  type tolerance = PLUS | EXACT | MINUS

  (* A token value ascribes an amount to token metadata *)
  type token_amount = {
     [@layout:comb]
     token : token;
     amount : nat;
  }


  type swap = {
   from : token_amount;
   to : token;
  }

  (*I change the type of the rate from tez to nat for sake of simplicity*)
  type exchange_rate = {
    [@layout:comb]
    swap : swap;
    rate: nat;
    when : timestamp;
  }

  type swap_order = {
    trader : address;
    swap  : swap;
    created_at : timestamp;
    side : side;
    tolerance : tolerance;
  }


  type batch_status  = NOT_OPEN | OPEN | CLOSED | FINALIZED

  type treasury_item_status = DEPOSITED | EXCHANGED | CLAIMED

  type treasury_item = {
   token_amount : token_amount;
   status : batch_status;
  }

  type treasury = (address, treasury_item) big_map

  type order_distribution = ((side * tolerance), nat) map


  type clearing = {
      clearing_volumes : (tolerance, nat)  map;
      clearing_tolerance : tolerance;
  }


  type batch = {
     started_at : timestamp option;
     closed_at : timestamp option;
     finalized_at : timestamp option;
     status : batch_status;
     batch_rate: exchange_rate option;
     orders: swap_order list;
     treasury: treasury;
     clearing : clearing option;
  }

  type batches = {
    current : batch;
    awaiting_clearing : batch option;
    previous : batch list;
  }


end

module Utils = struct
  let get_rate_name_from_swap (s : Types.swap) : string =
    let quote_name = s.to.name in
    let base_name = s.from.token.name in
    quote_name ^ "/" ^ base_name

  let get_rate_name (r : Types.exchange_rate) : string =
    let quote_name = r.swap.to.name in
    let base_name = r.swap.from.token.name in
    quote_name ^ "/" ^ base_name


  let get_new_current_batch : Types.batch =  {
              started_at = (None : timestamp option);
              closed_at =  (None : timestamp option);
              finalized_at = (None : timestamp option);
              status =  NOT_OPEN;
              batch_rate = (None : Types.exchange_rate option) ;
              orders = ([] : Types.swap_order list);
              treasury = (Big_map.empty :  (address, Types.treasury_item) big_map);
              clearing = (None : Types.clearing option)  ;
              }



end

