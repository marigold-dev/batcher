(** [concat a b] concat [a] and [b]. *)
let concat (type a) (left: a list) (right: a list) : a list =
  List.fold_right (fun (x, xs: a * a list) -> x :: xs) left right

(** [rev list] should return the same list reversed. *)
let rev (type a) (list: a list) : a list =
  List.fold_left (fun (xs, x : a list * a) -> x :: xs) ([] : a list) list


let pow (base : int) (pow : int) : int =
  let rec iter (acc : int) (rem_pow : int) : int = (if rem_pow = 0 then acc else iter (acc * base) (rem_pow - 1)) in
  iter (1) (pow)
