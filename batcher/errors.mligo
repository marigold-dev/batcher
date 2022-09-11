let not_a_valid_rate_pair = "Posted exchange rate is not a valid rate pair"
let no_rate_available_for_swap = "Posted swap doesn't have a corresponding exchange rate"

(* Treasury errors *)
let incorrect_address : string = "This address has not swapped any tokens"

let greater_than_owned_token : string = "This redeemed tokensx are greater than the owned tokens"

let invalid_token_address : string = "This token address is invalid"

let not_found_token : string = "This token is not found in the triggered treasury token"

let invalid_token : string = "This added token is not the same as the previous token"

let invalid_tezos_address : string = "This tezos address is invalid"


let insufficient_token_holding : string = "There is insufficient token holding to perform this swap"

let insufficient_token_holding_for_decrease : string = "There is not enough token holding at this address to perform the decrease required by the swap"


let no_treasury_holding_for_address : string = "There is no treasury holding for address"

let order_pair_doesnt_match = "The order pair and the batch pair don't match"

let tokens_do_not_match = "Tokens under comparison do not match"

let not_found_clearing_level : string = "This clearing level is not found"

let no_current_batch_available : string = "There is no current batch available"

let not_open_batch : string = "This current batch is not open"

let not_previous_batches : string = "This previous batches are not included"

let not_open_status : string = "This batch is not in open status"

let not_found_rate_name : string = "This current rate for these token pairs is not found"
