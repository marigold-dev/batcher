(* The constant which represents the period during which users can deposit, in seconds. *)
[@inline] let deposit_time_window : int = 180

(* The constant which represents the period during which a closed batch will wait before looking for a price, in seconds. *)
[@inline] let price_wait_window : int = 120

let fa12_token : string set = Set.literal ["tzBTC"]

let fa2_token : string set = Set.literal ["USDT"]
