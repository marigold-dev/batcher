#import "@ligo/math-lib/rational/rational.mligo" "Rational"

(* The constant which represents a 10 basis point difference *)
[@inline] let ten_bips_constant = Rational.div (Rational.new 10001) (Rational.new 10000)

(* The constant which represents they4j period during which a closed batch will wait before looking for a price, in seconds. *)
[@inline] let price_wait_window_in_seconds : int = 120

(* The minimum length of a the scale factor for oracle staleness *)
(* Oracle prices would be considered stale if they are older than scale_factor_for_oracle_staleness * deposit_time_window *)
[@inline] let minimum_scale_factor_for_oracle_staleness : nat = 1n

(* The maximum length of a the scale factor for oracle staleness *)
(* Oracle prices would be considered stale if they are older than scale_factor_for_oracle_staleness * deposit_time_window *)
[@inline] let maximum_scale_factor_for_oracle_staleness : nat = 10n

(* The minimum length of a deposit price window *)
[@inline] let minimum_deposit_time_in_seconds : nat = 600n

(* The maximum length of a deposit price window *)
[@inline] let maximum_deposit_time_in_seconds : nat = 3600n

[@inline] let fa12_token : string = "FA1.2 token"

[@inline] let fa2_token : string = "FA2 token"

[@inline] let limit_of_redeemable_items : nat = 10n

(* The contract assumes that the minimum precision is six and that the oracle precision must EXACTLY be 6 *)
[@inline] let minimum_precision : nat = 6n
