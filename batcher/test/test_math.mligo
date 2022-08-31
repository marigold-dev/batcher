#import "../math.mligo" "Math"
#import "../../math_lib/lib/float.mligo" "Float"
#import "../../breathalyzer/lib/lib.mligo" "Breath" 
#import "../types.mligo" "CommonTypes"

module Utils = struct 
  (* Create the main function for originating math module *)
  type parameter = Float.t * CommonTypes.Types.buy_side * CommonTypes.Types.sell_side
  type storage = int 

  let main (parameters, storage : parameter * storage) = 
    let (oracle_price, buy_side, sell_side) = parameters in 
    let clearing = Math.get_clearing_price oracle_price buy_side sell_side in 
    let { clearing_volumes; clearing_tolerance } = clearing in 
    let storage = 
      match Map.get_and_update
        clearing_tolerance 
        (None : Float.t option)
        clearing_volumes 
      with 
      | (Some cp, _clearing_volumes) -> cp.val
      | (None, _clearing_volumes) -> 1
    in 
    (([] : operation list), storage)

  (* Originate math module *)
  type originated = Breath.Contract.originated
  let originate_math (level: Breath.Logger.level) =
    let storage = 0 in 
    Breath.Contract.originate level "math" main storage 0tez

  (* Calculations of clearing price with the defined parameters *)
  let calculate_clearing_price
    (parameters : Float.t * CommonTypes.Types.buy_side * CommonTypes.Types.sell_side) 
    (contract : (parameter, storage) originated) 
    () = 
      Breath.Contract.transfert_to contract parameters 0tez
end 

let test_detect_clearing_price = 
  Breath.Model.case 
  "detect_clearing_price"
  "Trying to append the tokens and oracle price, and compute the clearing price at that time" 
  (fun (level : Breath.Logger.level) -> 
    let (_,(alice,_,_)) = Breath.Context.init_default () in
    let math_contract = Utils.originate_math level in
    let buy_side = (55, 100, 45) in 
    let sell_side = (1000, 1900, 900) in 
    let oracle_price = Float.new 19 (-1) in 
    let parameter = (oracle_price, buy_side, sell_side) in 
    let calculation_by_alice = Breath.Context.act_as alice (Utils.calculate_clearing_price parameter math_contract) in 
    let storage = Breath.Contract.storage_of math_contract in 
    Breath.Result.reduce [
      calculation_by_alice;
      Breath.Assert.is_equal "clearing_price" 200 storage
    ]
  )

let () = 
  Breath.Model.run_suites Void [
    Breath.Model.suite "Suite for Math" [
      test_detect_clearing_price
    ]
  ]


