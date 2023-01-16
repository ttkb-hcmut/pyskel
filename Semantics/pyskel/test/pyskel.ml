open PyreAst
open Pyskel.Utils.InterInst.Interpreter
module Utils = Pyskel.Utils

let print_flag flag =
  match flag with
  | Ret _ -> Printf.printf "Flag is %s\n" "Ret"
  | Brk -> Printf.printf "Flag is %s\n" "Brk"
  | Cont -> Printf.printf "Flag is %s\n" "Cont"
  | Exn _ -> Printf.printf "Flag is %s\n" "Exn"

let test_file file_name =
  print_endline "------------";
  print_endline file_name;
  (* Open file and get contents *)
  let file = open_in file_name in

  (* Get the first line (expected result) *)
  let first_line = input_line file in
  let expected_result = int_of_string (String.sub first_line 1 (String.length first_line - 1)) in

  let content = really_input_string file (in_channel_length file - String.length first_line - 1) in
  close_in file;

  (* Parse file *)
  let a = Parser.with_context (fun context ->
      Parser.Concrete.parse_module ~context content
  ) in

  (* Check for parse error *)
  Result.iter_error
    (fun Parser.Error.{message; line; column; _} ->
       Printf.fprintf stderr "Syntax error at (line %d, column %d):\n\t%s\n" line column message;
       exit 1;
    ) a;

  (* Eval file *)
  let ast = Utils.translate_ast (Result.get_ok a) in
  let fs = M.extract (eval_stmts ast) in
  let (builtins, heap) = M.extract @@ initializedHeap () in
  match M.extract (fs (builtins,
    { global_scope = initialEnv
    ; scope_heap = initialHeap
    ; heap = heap})) with
  | (Flag f, _) ->
    Printf.printf "Error, result is not Cur.\n";
    print_flag f
  | (Cur (), {global_scope = env; heap = heap; _}) -> begin
      match  M.extract @@ map_lookup ("__result__", env) with
      | Nothing -> failwith "var `__result__` is not defined."
      | Just addr -> begin
          (* Read the objN from heap *)
          let objn = fst @@ fst @@ M.extract @@ heapRead (heap, addr) in
          Printf.printf "Result is: %s\n" @@ Utils.show_objn objn;
          Printf.printf "Expected result is: %d\n" @@ expected_result
        end
    end

let _ =
  (* Read file name from command line args *)
  let test_directory = "python_tests" in

  if Stdlib.not (Sys.is_directory test_directory) then
      Printf.fprintf stderr "%s is not a directory" test_directory;

  let files = Sys.readdir test_directory in
  Sys.chdir test_directory;

  Array.iter test_file files

