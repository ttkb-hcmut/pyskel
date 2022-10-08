open Necromonads
open PyreAst

module Inst(M:MONAD) = struct
  module rec Types : sig
    include Pyskel.Constant_inst.TYPE
    include Pyskel.Env_inst.TYPE
      with type 'a maybe = 'a Pyskel.Semantics.Unspec(M)(Types).maybe
       and type addr = Pyskel.Semantics.Unspec(M)(Types).addr
    include Pyskel.Heap_inst.TYPE
      with type value = Pyskel.Semantics.Unspec(M)(Types).objN *
                        Pyskel.Semantics.Unspec(M)(Types).objS
  end = Types

  module Spec = struct
    include Pyskel.Semantics.Unspec(M)(Types)
    include Pyskel.Constant_inst.Spec(M)
    include Pyskel.Env_inst.Spec(M)
    include Pyskel.Heap_inst.Spec(M)
  end

  module Interpreter = Pyskel.Semantics.MakeInterpreter(Spec)
end

module InterInst = Inst(Necromonads.ContPoly)

open InterInst.Interpreter

let translate_expr (e: Concrete.Expression.t) : expr =
  match e with
  | Concrete.Expression.Constant {value = Concrete.Constant.True; _} ->
    Constant (CBool True)
  | Concrete.Expression.Constant {value = Concrete.Constant.False; _} ->
    Constant (CBool False)
  | Concrete.Expression.Constant {value = Concrete.Constant.None; _} ->
    Constant CNone
  | Concrete.Expression.Name {id = s; _}
    when Concrete.Identifier.to_string s = "NotImplemented" ->
    Name "NotImplemented"
  | Concrete.Expression.Constant {value = Concrete.Constant.Integer n; _} ->
    Constant (CInt n)
  | Concrete.Expression.Constant {value = Concrete.Constant.String s; _} ->
    Constant (CString s)
  | _ -> failwith "Not specified yet"

let translate_ast (m: Concrete.Module.t) : stmt =
  match m with
  | {Concrete.Module.body =
       [Concrete.Statement.Expr
          {value = e ; _}]; _} ->
    SExpr (translate_expr e)
  | {Concrete.Module.body =
       [Concrete.Statement.Assign {
           targets = Concrete.Expression.Name {id = x; _} :: _ ;
           value = e; _}]; _} ->
    SAssign(Concrete.Identifier.to_string x, translate_expr e)
  | _ -> failwith "statement not specified yet"


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
  let fs = M.extract (eval_stmt ast) in
  let (builtins, heap) = M.extract @@ initializedHeap () in
  match M.extract @@ M.extract (fs builtins) @@ (initialEnv, heap) with
  | (Flag _, _) -> Printf.printf "Error, result is not Cur.\n"
  | (Cur (), (env, heap)) -> begin
      match M.extract @@ getEnvData (env, "result") with
      | Nothing -> failwith "var `result` is not defined."
      | Just addr -> begin
          (* Read the objN from heap *)
          match fst @@ fst @@ M.extract @@ heapRead (heap, addr) with
          | Bool True -> Printf.printf "Result is True.\n"
          | Bool False -> Printf.printf "Result is False.\n"
          | None -> Printf.printf "Result is None.\n"
          | NotImplemented -> Printf.printf "Result is NotImplemented.\n"
          | Int n -> Printf.printf "Result is %d\n" n
          | String s -> Printf.printf "Result is \"%s\"\n" s
          | _ -> Printf.printf "Not able to understand your program yet"
        end
    end
