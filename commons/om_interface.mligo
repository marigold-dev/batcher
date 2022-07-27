(*For now i keep the asset part simple as possible so i deal with a simple sum types*)
type token = A | B

(*Direction define if a user is a buyer or a seller*)
type direction = Buyer | Seller

(* I think that for the POC, the expiry for a given order would be
  tezos.now + N, this expiry should be 
  created when the deposit is received by the treasury ? *)
type fixed_expiry = timestamp

(*
amount : the quantity of the given token the user want to trade
price : the price that the user is ready to pay for the amount of the given token
*)
type order = {
    trader : address;
    userType : direction;
    tokenType : token;
    amount : nat;
    price : nat;
    expiry : fixed_expiry
}

(*This type represent a result of a match computation, we can partially or totally match two orders*)
type match_result = Total | Partial of order 

(*
    Ordering -> push an order into the storage
    Tick -> triggering match/remove orders phase, which will be call periodically
*)
type entrypoints =
   Ordering of order
 | Tick