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
  Printf.printf "\n\n##################\n";
  Printf.printf "## %s\n" file_name;
  Printf.printf "##################\n";
  (* Open file and get contents *)
  let file = open_in file_name in

  (* Get the things to print *)
  let first_line = input_line file in
  let thing_to_print = (String.sub first_line 1 (String.length first_line - 1)) in

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

  (* Eval file with pyskel *)
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
          Printf.printf "Pyskel:\n%s\n" @@ Utils.show_objn objn;
        end
    end;

  (* Eval file with python *)
  let tmp_file = Filename.temp_file "" ".out" in
  Printf.printf "CPython: \n";
  ignore @@ Sys.command @@ Printf.sprintf
    "mktemp | xargs -I {} sh -c \"cat %s > {}; echo 'print(%s)' >> {} && python {}\" > %s"
    file_name thing_to_print tmp_file;
  let reader = open_in tmp_file in
  let rec loop () = Printf.printf "%s" (input_line reader) ; loop () in
  try loop () with _ -> close_in reader


let _ =
  (* Read file name from command line args *)
  let test_directory = "python_tests" in

  if Stdlib.not (Sys.is_directory test_directory) then
      Printf.fprintf stderr "%s is not a directory" test_directory;

  let files = Sys.readdir test_directory in
  Sys.chdir test_directory;

  Array.iter test_file files

