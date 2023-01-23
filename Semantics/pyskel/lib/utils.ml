open Necromonads
open PyreAst

module Inst(M:MONAD) = struct
  module rec Types : sig
    include Constant_inst.TYPE
    include Bool_inst.TYPE
    include Heap_inst.TYPE
    include Map_inst.TYPE
  end = Types

  module Spec = struct
    include Semantics.Unspec(M)(Types)
    include Constant_inst.Spec(M)
    include Bool_inst.Spec(M)
    include Map_inst.Spec(M)
    include Heap_inst.Spec(M)
  end

  module Interpreter = Semantics.MakeInterpreter(Spec)
  (* module Debuger = Debug.MakeDebuger(Spec) *)
end

module InterInst = Inst(Necromonads.ContPoly)

open InterInst.Interpreter

let to_pyskel_list (l : 'a Stdlib.List.t) : 'a list =
  Stdlib.List.fold_right (fun h t -> Cons(h, t)) l Nil

let rec to_standard_list (l : 'a list) : 'a Stdlib.List.t =
  match l with
  | Nil -> []
  | Cons(h, t) -> h :: (to_standard_list t)


let rec translate_expr (e: Concrete.Expression.t) : expr =
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
  | Concrete.Expression.Call {func = f; args = args; _} ->
    Call(translate_expr f, to_pyskel_list @@ Stdlib.List.map translate_expr args)
  | Concrete.Expression.Attribute { value; attr; _} ->
    Attribute (translate_expr value, Concrete.Identifier.to_string attr)
  | _ -> failwith "Expression not specified yet"

let translate_argument ({identifier = id; _} : Concrete.Argument.t)
  : Concrete.Identifier.t =
  id

let translate_arguments ({args = args; _} : Concrete.Arguments.t)
  : Concrete.Identifier.t Stdlib.List.t =
  Stdlib.List.map translate_argument args

let translate_keyword ({arg; value; _} : Concrete.Keyword.t)
  : id * expr =
  (Concrete.Identifier.to_string @@ Option.get arg, translate_expr value)

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
  | Concrete.Statement.Return {value = Some e; _} ->
    SReturn (translate_expr e)
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
  | Concrete.Statement.Nonlocal {names = [id]; _} ->
    SNonlocal (Concrete.Identifier.to_string id)
  | Concrete.Statement.Global {names = [id]; _} ->
    SGlobal (Concrete.Identifier.to_string id)
  | Concrete.Statement.ClassDef {name; bases; keywords; body; _} ->
    SClassDef(Concrete.Identifier.to_string name,
              to_pyskel_list @@ Stdlib.List.map translate_expr bases,
              to_pyskel_list @@ Stdlib.List.map translate_keyword keywords,
              to_pyskel_list @@ Stdlib.List.map translate_stmt body)
  | _ -> failwith "statement not specified yet"


let translate_ast (m: Concrete.Module.t) : stmt list =
  match m with
  | {Concrete.Module.body = stmts; _} -> to_pyskel_list @@ Stdlib.List.map translate_stmt stmts


module SMap = Map.Make(String)
module IMap = Map.Make(Int)
let rec show_dict (heap: (objN * objS) IMap.t) (dict: addr SMap.t) =
  "{" ^ (Stdlib.String.concat ", "
      @@ Stdlib.List.map (fun (key, value) ->
           Printf.sprintf "%s = %s" key (show_objn heap @@ fst @@ IMap.find value heap))
      @@ SMap.bindings dict) ^ "}"
and show_objn (heap: (objN * objS) IMap.t) (x: objN) =
  match x with
  | Bool True -> "True"
  | Bool False -> "False"
  | None -> "None"
  | NotImplemented -> "NotImplemented"
  | Int n ->
     Printf.sprintf "%d" n;
  | String s -> Printf.sprintf "\"%s\"" s
  | Fun(name, args, locals, _body, _scope_up) ->
    Printf.sprintf "<function %s(%s) with locals = (%s)>"
      name
      (Stdlib.List.fold_left (fun s p -> s ^ p ^ ", ") "" @@ to_standard_list args)
      (Stdlib.List.fold_left (fun s p -> s ^ "'" ^ p ^ "'" ^ ", ") "" @@ to_standard_list locals)
  | Class(name, _, _, dict) ->
    Printf.sprintf "class %s %s" name (show_dict heap dict)
  | _ -> Printf.sprintf "Unknown"
