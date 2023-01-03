#import "../math_lib/lib/rational.mligo" "Rational"


(* The constant which represents a 10 basis point difference *)
[@inline] let ten_bips_constant = Rational.div (Rational.new 10001) (Rational.new 10000)

(* The constant which represents the period during which users can deposit, in seconds. *)
[@inline] let deposit_time_window : int = 600

(* The constant which represents the period during which a closed batch will wait before looking for a price, in seconds. *)
[@inline] let price_wait_window : int = 120

[@inline] let fa12_token : string = "FA1.2 token"

[@inline] let fa2_token : string = "FA2 token"

[@inline] let bids : string = "bids"

[@inline] let asks : string = "asks"

[@inline] let open : string = "open"

[@inline] let redeemed : string = "redeemed"

(* Number of seconds after order placement time should the order be removed if it has been redeemed - current default 1 day *)
[@inline] let redeemed_order_removal_time : int = 86400


[@inline] let limit_of_redeemable_items : nat = 10n



