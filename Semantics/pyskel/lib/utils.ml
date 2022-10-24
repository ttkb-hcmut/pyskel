open Necromonads
open PyreAst

module Inst(M:MONAD) = struct
  module rec Types : sig
    include Constant_inst.TYPE
    include Env_inst.TYPE
      with type 'a maybe = 'a Semantics.Unspec(M)(Types).maybe
       and type addr = Semantics.Unspec(M)(Types).addr
    include Heap_inst.TYPE
      with type value = Semantics.Unspec(M)(Types).objN *
                        Semantics.Unspec(M)(Types).objS
  end = Types

  module Spec = struct
    include Semantics.Unspec(M)(Types)
    include Constant_inst.Spec(M)
    include Env_inst.Spec(M)
    include Heap_inst.Spec(M)
  end

  module Interpreter = Semantics.MakeInterpreter(Spec)
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
