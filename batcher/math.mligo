module Utils = struct

let min (a : nat) (b : nat) = if a <= b then a else b

let clearing_prices
    (_p: nat)
    (_x: nat) (_y: nat) (_z: nat)
    (_r: nat) (_s: nat) (_t: nat)
=
    let clearing = {
      clearing_volumes =
                         Map.literal [
                                      (PLUS, 0n);
                                      (EXACT, 0n);
                                      (MINUS, 0n)
                                     ];
      clearing_tolerance = EXACT;
    } in
    clearing

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
    let cv_minus =
        let left = x + y + z in
        let right = r * ((1.0001)/p) in
        min left right in

    let cv_exact =
        let left = y + z in
        let right = (r + s) * (1/p) in
        min left right in

    let cv_plus =
        let right = (r+s+t) * (1/(p* 1.0001)) in
        min z right in

    let clearing_tolerance =
       let clearing_volume = max cv_plus cv_exact cv_minus in
       let tol = PLUS in
       let tol = if clearing_volume = cv_exact then EXACT else tol in
       let tol = if clearing_volume = cv_minus then MINUS else tol in
       tol

    let clearing = {
      clearing_volumes =
                         Map.literal [
                                      (PLUS, cv_plus);
                                      (EXACT, cv_exact);
                                      (MINUS, cv_minus)
                                     ];
      clearing_tolerance = clearing_tolerance;
    } in
    clearing *)
end
