#import "parameter.mligo" "Parameter" 
#import "storage.mligo" "Storage"

type storage = Storage.Types.t 
type action = Parameter.Types.t

let main (action, storage : action * storage) = 
  match action with 
  | Deposit deposited_value -> 
    let storage = Storage.Utils.deposit deposited_value storage in 
    (([] : operation list), storage)
  | Redeem redeemed_value -> 
    let storage = Storage.Utils.redeem redeemed_value storage in 
    (([] : operation list), storage) 