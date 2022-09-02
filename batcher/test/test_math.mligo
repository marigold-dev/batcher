#import "../math.mligo" "Math"
#import "../../math_lib/lib/float.mligo" "Float"
#import "../../breathalyzer/lib/lib.mligo" "Breath" 
#import "../types.mligo" "CommonTypes"
#import "../errors.mligo" "CommonErrors"

module Utils = struct 
  (* Create the main function for originating math module *)
  type parameter = Float.t * CommonTypes.Types.buy_side * CommonTypes.Types.sell_side
  type storage = nat 
  type return = operation list * storage

  let main (parameters, _storage : parameter * storage) : return = 
    let (rate, buy_side, sell_side) = parameters in 
    let clearing = Math.get_clearing_price rate buy_side sell_side in 
    let { clearing_volumes; clearing_tolerance } = clearing in 
    match Map.get_and_update
      clearing_tolerance 
      (None : nat option)
      clearing_volumes 
    with 
    | (Some clearing_price, _clearing_volumes) -> (([] : operation list), clearing_price)
    | (None, _clearing_volumes) -> failwith CommonErrors.not_found_clearing_level

  (* Originate math module *)
  type originated = Breath.Contract.originated
  let originate_math (level: Breath.Logger.level) =
    let storage = 0n in 
    Breath.Contract.originate level "math" main storage 0tez

  (* Calculations of clearing price with the defined parameters *)
  let calculate_clearing_price
    (parameters : parameter) 
    (contract : (parameter, storage) originated) 
    () = 
      Breath.Contract.transfert_to contract parameters 0tez
end 

let test_detect_minus_clearing_price = 
  Breath.Model.case 
  "detect_minus_clearing_price"
  "Trying to append oracle price and tokens in 2 sides. This calculated clearing price is in the minus clearing level" 
  (fun (level : Breath.Logger.level) -> 
    let (_,(alice,_,_)) = Breath.Context.init_default () in
    let math_contract = Utils.originate_math level in
    let buy_side = (1, 2, 1) in 
    let sell_side = (600000, 1200000, 500000) in 
    let rate = Float.new 21703 0 in 
    let parameter = (rate, buy_side, sell_side) in 
    let calculation_by_alice = Breath.Context.act_as alice (Utils.calculate_clearing_price parameter math_contract) in 
    let storage = Breath.Contract.storage_of math_contract in 
    Breath.Result.reduce [
      calculation_by_alice;
      Breath.Assert.is_equal "minus_clearing_price" 4n storage
    ]
  )

let test_detect_exact_clearing_price = 
  Breath.Model.case 
  "detect_exact_clearing_price"
  "Trying to append oracle price and tokens in 2 sides. This calculated clearing price is in the exact clearing level" 
  (fun (level : Breath.Logger.level) -> 
    let (_,(alice,_,_)) = Breath.Context.init_default () in
    let math_contract = Utils.originate_math level in
    let buy_side = (5, 5, 10) in 
    let sell_side = (250000, 100000, 100000) in 
    let rate = Float.new 21703 0 in 
    let parameter = (rate, buy_side, sell_side) in 
    let calculation_by_alice = Breath.Context.act_as alice (Utils.calculate_clearing_price parameter math_contract) in 
    let storage = Breath.Contract.storage_of math_contract in 
    Breath.Result.reduce [
      calculation_by_alice;
      Breath.Assert.is_equal "exact_clearing_price" 15n storage
    ]
  )

let test_detect_plus_clearing_price = 
  Breath.Model.case 
  "detect_plus_clearing_price"
  "Trying to append oracle price and tokens in 2 sides. This calculated clearing price is in the plus clearing level" 
  (fun (level : Breath.Logger.level) -> 
    let (_,(alice,_,_)) = Breath.Context.init_default () in
    let math_contract = Utils.originate_math level in
    let buy_side = (50, 100, 50) in 
    let sell_side = (200000, 400000, 100000) in 
    let rate = Float.new 21703 0 in 
    let parameter = (rate, buy_side, sell_side) in 
    let calculation_by_alice = Breath.Context.act_as alice (Utils.calculate_clearing_price parameter math_contract) in 
    let storage = Breath.Contract.storage_of math_contract in 
    Breath.Result.reduce [
      calculation_by_alice;
      Breath.Assert.is_equal "plus_clearing_price" 32n storage
    ]
  )


let () = 
  Breath.Model.run_suites Void [
    Breath.Model.suite "Suite for Math" [
      test_detect_minus_clearing_price;
      test_detect_exact_clearing_price;
      test_detect_plus_clearing_price
    ]
  ]


