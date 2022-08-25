#import "types.mligo" "CommonTypes"
#import "constants.mligo" "Constants"

module Types = CommonTypes.Types

type batch_status =
  | Open of { start_time : timestamp }
  | Closed of { start_time : timestamp ; closing_time : timestamp }
  | Cleared of { at : timestamp; clearing : Types.clearing; rate : Types.exchange_rate }

(* Batch of orders for the same pair of tokens *)
type t = {
  status : batch_status;
  treasury : Types.treasury;
  orders : Types.swap_order list;
  pair : Types.token * Types.token;
}