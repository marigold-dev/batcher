module Utils = struct

let min (a : nat) (b : nat) = if a <= b then a else b

let clearing_prices 
    (_p: nat) 
    (_x: nat) (_y: nat) (_z: nat) 
    (_r: nat) (_s: nat) (_t: nat)
=
    (0n,0n,0n,0n,0n,0n)

(*
We have ton install the math-lib-cameligo in order to use float instead of nat
but i don't know how to find the package name.

remove the next comment when the package is installed, will need some change in anycase
its more a placeholder taken from the design document than real code.
*)

(*let clearing_prices 
    (p: nat) 
    (x: nat) (y: nat) (z: nat) 
    (r: nat) (s: nat) (t: nat)
=
    let sell_cp_minus =
        let left = x + y + z in
        let right = r * ((1.0001)/p) in
        min left right in

    let sell_cp_exact =
        let left = y + z in
        let right = (r + s) * (1/p) in
        min left right in

    let sell_cp_plus =
        let right = (r+s+t) * (1/(p* 1.0001)) in
        min z right in

    let buy_cp_minus =
        let left = x + y + z in
        let right = r * (p/1.0001) in
        min left right in

    let buy_cp_exact =
        let left = y + z in
        let right = (r + s) * p in
        min left right in

    let buy_cp_plus =
        let right = (r+s+t) * (p* 1.0001) in
        min z right in
    
    (sell_cp_minus,sell_cp_exact,sell_cp_plus,buy_cp_minus,buy_cp_exact,buy_cp_plus)*)
end