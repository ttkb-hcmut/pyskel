open Pyskel.Utils.InterInst.Interpreter
module Utils = Pyskel.Utils

let run_file (builtins, heap) file_name =
  (* Open file and get contents *)
  let file = open_in file_name in
  let contents = really_input_string file (in_channel_length file - 1) in
  close_in file;

  let (_, result) = Utils.eval_file_with_prelude builtins heap contents in

  (* Eval file with pyskel *)
  match result with
  | (Flag f, {heap; _}) ->
    Printf.printf "Error, result is not Cur.\n";
    Printf.printf "%s" @@ Utils.show_flag (fst heap) f
  | (Cur (), {global_scope = env; heap = (heap, _); _}) -> begin
      let module SMap = Map.Make(String) in
      let module IMap = Map.Make(Int) in
      match SMap.find_opt "__result__" env with
      | None -> failwith "var `__result__` is not defined."
      | Some addr -> begin
          (* Read the objN from heap *)
          let objn = fst @@ IMap.find addr heap in
          Printf.printf " Pyskel: %s\n" @@ Utils.show_objn heap objn;
        end
    end

let _ =
  (* Read file name from command line args *)
  let file_name = Sys.argv.(1) in

  let prelude = open_in "test/python_files/prelude.py" in
  let contents = really_input_string prelude (in_channel_length prelude) in

  let (builtins, (result, heap)) = Utils.eval_file contents in
  close_in prelude;
  begin
    match result with
    | Utils.InterInst.Interpreter.Cur _ -> ()
    | _ -> failwith "Evaluation of prelude failed !"
  end;

  run_file (builtins, heap) file_name
