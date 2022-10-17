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

let to_pyskel_list (l : 'a Stdlib.List.t) : 'a list =
  Stdlib.List.fold_right (fun h t -> Cons(h, t)) l Nil

let rec to_standard_list (l : 'a list) : 'a Stdlib.List.t =
  match l with
  | Nil -> []
  | Cons(h, t) -> h :: (to_standard_list t)


let translate_expr (e: Concrete.Expression.t) : expr =
  match e with
  | Concrete.Expression.Constant {value = Concrete.Constant.True; _} ->
    Constant (CBool True)
  | Concrete.Expression.Constant {value = Concrete.Constant.False; _} ->
    Constant (CBool False)
  | Concrete.Expression.Constant {value = Concrete.Constant.None; _} ->
    Constant CNone
  | Concrete.Expression.Name {id = s; _} ->
    Name (Concrete.Identifier.to_string s)
  | Concrete.Expression.Constant {value = Concrete.Constant.Integer n; _} ->
    Constant (CInt n)
  | Concrete.Expression.Constant {value = Concrete.Constant.String s; _} ->
    Constant (CString s)
  | _ -> failwith "Not specified yet"

let translate_argument ({identifier = id; _} : Concrete.Argument.t)
  : Concrete.Identifier.t =
  id

let translate_arguments ({args = args; _} : Concrete.Arguments.t)
  : Concrete.Identifier.t Stdlib.List.t =
  Stdlib.List.map translate_argument args

let rec translate_stmt (s : Concrete.Statement.t) : stmt =
  match s with
  | Concrete.Statement.Expr {value = e ; _} ->
    SExpr (translate_expr e)
  | Concrete.Statement.Assign {
      targets = Concrete.Expression.Name {id = x; _} :: _ ;
      value = e; _} ->
    SAssign(Concrete.Identifier.to_string x, translate_expr e)
  | Concrete.Statement.Delete {
      targets = Concrete.Expression.Name {id = x; _} :: _
    ; _} ->
    SDel(Concrete.Identifier.to_string x)
  | Concrete.Statement.FunctionDef {
      name = name;
      args = args;
      body = body;
      _
    } ->
    let stmts = to_pyskel_list @@ Stdlib.List.map translate_stmt body in
    let arguments =
      to_pyskel_list @@
      Stdlib.List.map Concrete.Identifier.to_string @@
      translate_arguments args in
    SFunctionDef(Concrete.Identifier.to_string name, arguments, stmts)
  | _ -> failwith "statement not specified yet"


let translate_ast (m: Concrete.Module.t) : stmt =
  match m with
  | {Concrete.Module.body = [stmt]; _} -> translate_stmt stmt
  | _ -> failwith "Multiple statements are not supported."


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
              (Stdlib.List.fold_left (fun s p -> s ^ p ^ ", ") "" @@ to_standard_list args)
              (Stdlib.List.fold_left (fun s p -> s ^ p ^ ", ") "" @@ to_standard_list locals)
          | _ -> Printf.printf "Not able to understand your program yet"
        end
    end
