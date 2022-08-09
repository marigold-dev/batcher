let list_rev (type a) (list: a list) : a list = 
  List.fold_left (fun (xs, x: a list * a) -> x :: xs) ([] : a list) list

let list_concat (type a) (left: a list) (right: a list) : a list = 
  List.fold_right (fun (x, xs : a * a list) -> x :: xs) left right
