#import "parameter.mligo" "Parameter" 
#import "storage.mligo" "Storage"

type storage = Storage.Types.t 
type action = Parameter.Types.t

let main (action, storage : action * storage) = 
  let address = Tezos.get_sender () in 
  match action with 
  | Deposit deposited_value -> 
    let storage = Storage.Utils.deposit address deposited_value storage in 
    (([] : operation list), storage)
  | Redeem redeemed_value -> 
    let storage = Storage.Utils.redeem address redeemed_value storage in 
    (([] : operation list), storage) 