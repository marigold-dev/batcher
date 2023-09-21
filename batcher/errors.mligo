
[@inline] let no_rate_available_for_swap : nat                                   = 100n
[@inline] let invalid_token_address : nat                                        = 101n
[@inline] let invalid_tezos_address : nat                                        = 102n
[@inline] let no_open_batch : nat                                                = 103n
[@inline] let batch_should_be_cleared : nat                                      = 104n
[@inline] let trying_to_close_batch_which_is_not_open : nat                      = 105n
[@inline] let unable_to_parse_side_from_external_order : nat                     = 106n
[@inline] let unable_to_parse_tolerance_from_external_order : nat                = 107n
[@inline] let token_standard_not_found : nat                                     = 108n
[@inline] let xtz_not_currently_supported : nat                                  = 109n
[@inline] let unsupported_swap_type : nat                                        = 110n
[@inline] let unable_to_reduce_token_amount_to_less_than_zero : nat              = 111n
[@inline] let too_many_unredeemed_orders : nat                                   = 112n
[@inline] let insufficient_swap_fee : nat                                        = 113n
[@inline] let sender_not_administrator : nat                                     = 114n
[@inline] let token_already_exists_but_details_are_different: nat                = 115n
[@inline] let swap_already_exists: nat                                           = 116n
[@inline] let swap_does_not_exist: nat                                           = 117n
[@inline] let endpoint_does_not_accept_tez: nat                                  = 118n
[@inline] let number_is_not_a_nat: nat                                           = 119n
[@inline] let oracle_price_is_stale: nat                                         = 120n
[@inline] let oracle_price_is_not_timely: nat                                    = 121n
[@inline] let unable_to_get_price_from_oracle: nat                               = 122n
[@inline] let unable_to_get_price_from_new_oracle_source: nat                    = 123n
[@inline] let oracle_price_should_be_available_before_deposit: nat               = 124n
[@inline] let swap_is_disabled_for_deposits: nat                                 = 125n
[@inline] let upper_limit_on_tokens_has_been_reached: nat                        = 126n
[@inline] let upper_limit_on_swap_pairs_has_been_reached: nat                    = 127n
[@inline] let cannot_reduce_limit_on_tokens_to_less_than_already_exists: nat     = 128n
[@inline] let cannot_reduce_limit_on_swap_pairs_to_less_than_already_exists: nat = 129n
[@inline] let more_tez_sent_than_fee_cost : nat                                  = 130n
[@inline] let cannot_update_deposit_window_to_less_than_the_minimum : nat        = 131n
[@inline] let cannot_update_deposit_window_to_more_than_the_maximum : nat        = 132n
[@inline] let oracle_must_be_equal_to_minimum_precision : nat                    = 133n
[@inline] let swap_precision_is_less_than_minimum : nat                          = 134n
[@inline] let cannot_update_scale_factor_to_less_than_the_minimum : nat          = 135n
[@inline] let cannot_update_scale_factor_to_more_than_the_maximum : nat          = 136n
[@inline] let cannot_remove_swap_pair_that_is_not_disabled : nat                 = 137n
[@inline] let token_name_not_in_list_of_valid_tokens : nat                       = 138n
[@inline] let no_orders_for_user_address : nat                                   = 139n
[@inline] let cannot_cancel_orders_for_a_batch_that_is_not_open : nat            = 140n
[@inline] let cannot_decrease_holdings_of_removed_batch : nat                    = 141n
[@inline] let cannot_increase_holdings_of_batch_that_does_not_exist : nat        = 142n
[@inline] let batch_already_removed : nat                                        = 143n
[@inline] let admin_and_fee_recipient_address_cannot_be_the_same                 = 144n
[@inline] let incorrect_market_vault_holder                                      = 145n
[@inline] let incorrect_market_vault_id                                          = 146n
[@inline] let market_vault_tokens_are_different                                  = 147n
[@inline] let unable_to_find_user_holding_for_id                                 = 148n
[@inline] let unable_to_find_vault_holding_for_id                                = 149n
[@inline] let user_in_holding_is_incorrect                                       = 150n
[@inline] let no_holding_in_market_maker_for_holder                              = 151n
[@inline] let no_market_vault_for_token                                          = 152n
[@inline] let holding_amount_to_redeem_is_larger_than_holding                    = 153n
[@inline] let holding_shares_greater_than_total_shares_remaining                 = 154n
[@inline] let no_holdings_to_claim                                               = 155n
[@inline] let incorrect_side_specified                                           = 156n
[@inline] let entrypoint_does_not_exist                                          = 157n
[@inline] let unable_to_get_reduced_batches_from_batcher                         = 158n
[@inline] let unable_to_get_oracle_price                                         = 159n
[@inline] let contract_does_not_exist                                            = 160n
[@inline] let unable_to_call_on_chain_view                                       = 161n
