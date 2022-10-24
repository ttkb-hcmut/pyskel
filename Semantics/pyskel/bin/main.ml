open PyreAst
open Pyskel.Utils.InterInst.Interpreter
module Utils = Pyskel.Utils

let _ =
  (* Read file name from command line args *)
  let file_name =
    if Array.length Sys.argv <= 1 then begin
      Printf.fprintf stderr "Please specify an input file.\n";
      exit 1
    end else
      Sys.argv.(1) in

  (* Open file and get contents *)
  let file = open_in file_name in
  let content = really_input_string file (in_channel_length file) in
  close_in file;

  (* Parse file *)
  let a = Parser.with_context @@ (fun context ->
      Parser.Concrete.parse_module ~context content) in

  (* Check for parse error *)
  Result.iter_error
    (fun Parser.Error.{message; line; column; _} ->
       Printf.fprintf stderr "Syntax error at (line %d, column %d):\n\t%s\n" line column message;
       exit 1;

    ) a;

  (* Eval file *)
  let ast = Utils.translate_ast (Result.get_ok a) in
  let fs = M.extract (eval_stmt ast) in
  let (builtins, heap) = M.extract @@ initializedHeap () in
  match M.extract @@ M.extract (fs builtins) @@ (initialEnv, heap) with
  | (Flag _, _) -> Printf.printf "Error, result is not Cur.\n"
  | (Cur (), (env, heap)) -> begin
      match M.extract @@ getEnvData (env, "__result__") with
      | Nothing -> failwith "var `__result__` is not defined."
      | Just addr -> begin
          (* Read the objN from heap *)
          match fst @@ fst @@ M.extract @@ heapRead (heap, addr) with
          | Bool True -> Printf.printf "Result is True.\n"
          | Bool False -> Printf.printf "Result is False.\n"
          | None -> Printf.printf "Result is None.\n"
          | NotImplemented -> Printf.printf "Result is NotImplemented.\n"
          | Int n -> Printf.printf "Result is %d\n" n
          | String s -> Printf.printf "Result is \"%s\"\n" s
          | Fun(name, args, locals, _body) ->
            Printf.printf "Result is function %s(%s) with locals = (%s)\n"
              name
              (Stdlib.List.fold_left (fun s p -> s ^ p ^ ", ") "" @@ Utils.to_standard_list args)
              (Stdlib.List.fold_left (fun s p -> s ^ p ^ ", ") "" @@ Utils.to_standard_list locals)
          | _ -> Printf.printf "Not able to understand your program yet"
        end
    end
