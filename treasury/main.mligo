#import "../commons/types.mligo" "CommonTypes" 
#import "../commons/storage.mligo" "CommonStorage"
#import "treasury.mligo" "Treasury"

type storage = CommonStorage.Types.treasury
type action = 
| Deposit of CommonTypes.Types.deposit
| Redeem of CommonTypes.Types.redeem

let main (action, storage : action * storage) = 
  let address = Tezos.get_sender () in 
  match action with 
  | Deposit deposited_value -> 
    let storage = Treasury.Utils.deposit address deposited_value storage in 
    (([] : operation list), storage)
  | Redeem redeemed_value -> 
    let storage = Treasury.Utils.redeem address redeemed_value storage in 
    (([] : operation list), storage) 