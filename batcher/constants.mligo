#import "../math_lib/lib/float.mligo" "Float"

(* The constant which represents the period during which users can deposit, in seconds. *)
[@inline] let deposit_time_window : int = 600

(* The constant which represents the period during which a closed batch will wait before looking for a price, in seconds. *)
[@inline] let price_wait_window : int = 120

[@inline] let fa12_token : string = "FA1.2 token"

[@inline] let fa2_token : string = "FA2 token"

[@inline] let constant_number = Float.add (Float.new 1 0) (Float.new 1 (-4))
