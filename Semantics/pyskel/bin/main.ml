open Necromonads
open PyreAst

module Inst(M:MONAD) = struct
  module rec Types : sig
    include Pyskel.Constant_inst.TYPE
    include Pyskel.Heap_inst.TYPE
      with type value = Pyskel.Constant.Unspec(M)(Types).objN *
                        Pyskel.Constant.Unspec(M)(Types).objS
    include Pyskel.Env_inst.TYPE
      with type envData = Pyskel.Constant.Unspec(M)(Types).envData
  end = Types

  module Spec = struct
    include Pyskel.Constant.Unspec(M)(Types)
    include Pyskel.Constant_inst.Spec(M)
    include Pyskel.Env_inst.Spec(M)
    include Pyskel.Heap_inst.Spec(M)
  end

  module Interpreter = Pyskel.Constant.MakeInterpreter(Spec)
end

module InterInst = Inst(Necromonads.ContPoly)

open InterInst.Interpreter

let translate_ast (m: Concrete.Module.t) : objN =
  match m with
  | {Concrete.Module.body =
       [Concrete.Statement.Expr
          {value = Concrete.Expression.Constant
               {value = Concrete.Constant.True; _}; _}]; _} ->
    Bool True
  | {Concrete.Module.body =
       [Concrete.Statement.Expr
          {value = Concrete.Expression.Constant
               {value = Concrete.Constant.False; _}; _}]; _} ->
    Bool False
  | {Concrete.Module.body =
       [Concrete.Statement.Expr
          {value = Concrete.Expression.Constant
               {value = Concrete.Constant.None; _}; _}]; _} ->
    None
  | {Concrete.Module.body =
       [Concrete.Statement.Expr
          {value = Concrete.Expression.Name {id = s; _}; _}]; _}
    when Concrete.Identifier.to_string s = "NotImplemented" ->
    NotImplemented
  | {Concrete.Module.body =
       [Concrete.Statement.Expr
          {value = Concrete.Expression.Constant
               {value = Concrete.Constant.Integer n; _}; _}]; _} ->
    Int n
  | {Concrete.Module.body =
       [Concrete.Statement.Expr
          {value = Concrete.Expression.Constant
               {value = Concrete.Constant.String s; _}; _}]; _} ->
    String s
  | _ -> failwith "Not specified yet"


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
  let ast = translate_ast (Result.get_ok a) in
  let fs = M.extract (eval ast) in
  let (builtins, heap) = M.extract @@ initializedHeap () in
  match M.extract @@ M.extract (fs builtins) @@ (initialEnv, heap) with
  | (Flag _, _) -> Printf.printf "Error, result is not Cur.\n"
  | (Cur v, (_, heap)) -> begin
      (* Read the objN from heap *)
      match fst @@ fst @@ M.extract @@ heapRead (heap, v) with
      | Bool True -> Printf.printf "Result is \"True\".\n"
      | Bool False -> Printf.printf "Result is \"False\".\n"
      | None -> Printf.printf "Result is \"None\".\n"
      | NotImplemented -> Printf.printf "Result is \"NotImplemented\".\n"
      | Int n -> Printf.printf "Result is \"Integer : %d\"\n" n
      | String s -> Printf.printf "Result is \"String : '%s'\"\n" s
      | _ -> Printf.printf "Not able to understand your program yet"
    end
