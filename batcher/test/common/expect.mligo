#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
(*
This function is ported from the breathlyser library due to it not being in the packeged version.  Once the method is available in the package, the method can be replaced.
*)


let fail_with_value (type a) (value: a) (result: Breath.Result.result) : Breath.Result.result =
  match result with
  | Failed [Execution (Rejected (mp, _))] ->
    let value_mp = Test.compile_value value in
    if Test.michelson_equal mp value_mp then Breath.Result.succeed
    else
      let full_value =
        "Expected failure: `"
        ^ (Test.to_string value) ^ "` but: `"
        ^ (Test.to_string mp)
        ^ "` given"
      in
      Breath.Result.fail_with full_value
  | _ -> Breath.Result.fail_with ("Expected failure: `" ^ (Test.to_string value) ^ "`")
