(*For now i keep the asset part simple as possible so i deal with a simple sum types*)

type token = A | B

(* I think that for the POC, the expiry for a given order would be
  tezos.now + N, this expiry should be 
  created when the deposit is received by the treasury ? *)
type fixed_expiry = timestamp

type order = {
    trader : address;
    tokenType : token;
    amount : nat;
    expiry : fixed_expiry
}

(*
    Ordering -> push an order into the storage
    Tick -> triggering match/remove orders phase, which will be call periodically
*)
type entrypoints =
   Ordering of order
 | Tick