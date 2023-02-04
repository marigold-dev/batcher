let not_a_valid_rate_pair : nat = 100n

let no_rate_available_for_swap : nat = 101n

(* Treasury errors *)
let incorrect_address : nat = 102n

let greater_than_owned_token : nat = 103n

let invalid_token_address : nat = 104n

let not_found_token : nat = 105n

let invalid_token : nat = 106n

let invalid_tezos_address : nat = 107n

let insufficient_token_holding : nat = 108n

let insufficient_token_holding_for_decrease : nat = 109n

let no_treasury_holding_for_address : nat = 110n

let order_pair_doesnt_match = "Not the correct token pair"

let tokens_do_not_match = 112n

let not_found_clearing_level : nat = 113n

let no_current_batch_available : nat = 114n

let no_open_batch_for_deposits : nat = 115n

let not_previous_batches : nat = 116n

let not_open_status : nat = 117n

let not_found_rate_name : nat = 118n

let batch_should_be_cleared : nat = 119n

let trying_to_close_batch_which_is_not_open : nat = 120n

let trying_to_finalize_batch_which_is_not_closed : nat = 121n

let append_an_order_to_a_non_open_batch : nat = 122n

let append_an_order_with_no_current_batch : nat = 123n

let unable_to_parse_side_from_external_order : nat = 124n

let unable_to_parse_tolerance_from_external_order : nat = 125n

let not_found_token_standard : nat = 126n

let unable_to_find_side_in_orderbook : nat = 127n

let xtz_not_currently_supported : nat = 128n

let unsupported_swap_type : nat = 129n

let unable_to_determine_current_or_previous_batch : nat = 130n

let unable_to_reduce_token_amount_to_less_than_zero : nat = 131n

let too_many_unredeemed_orders : nat = 132n

let insufficient_swap_fee : nat =  133n

let sender_not_administrator : nat =  134n

let token_already_exists_but_details_are_different: nat = 135n

let swap_already_exists: nat = 136n

let swap_does_not_exist: nat = 137n

let inverted_swap_already_exists: nat = 138n
