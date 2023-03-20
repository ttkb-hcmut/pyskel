open Necromonads
open PyreAst

module Inst(M:MONAD) = struct
  module rec Types : sig
    include Constant_inst.TYPE
    include Bool_inst.TYPE
    include Heap_inst.TYPE
    include Map_inst.TYPE
    include Exn_inst.TYPE

    type internal = IntAdd
  end = Types


  module Spec = struct
    include Semantics.Unspec(M)(Types)
    include Constant_inst.Spec(M)
    include Bool_inst.Spec(M)
    include Map_inst.Spec(M)
    include Heap_inst.Spec(M)
    include Exn_inst.Spec(M)

    let call_internal (op, args) = M.ret @@
      fun (r, s) ->
      match op with
      | Types.IntAdd ->
        match args with
        | Cons (op1, (Cons (op2, Nil))) ->
          let (let*) = M.bind in
          let* ((at1, _), heap) = heapRead (s.heap, op1) in
          let* ((at2, _), heap) = heapRead (heap, op2) in begin
            match at1, at2 with
            |Int left, Int right ->
              let* (result, heap) = heapAlloc (heap, (Int (left + right), Locked)) in
              M.ret (Cur result, {s with heap})
            | _ -> failwith "Wrong type of arguments"
          end
        | _ -> failwith "Wrong number of arguments"
  end

  module Interpreter = Semantics.MakeInterpreter(Spec)
  (* module Debuger = Debug.MakeDebuger(Spec) *)
end

module InterInst = Inst(Necromonads.ContPoly)

open InterInst.Interpreter

let to_pyskel_list (l : 'a Stdlib.List.t) : 'a list =
  Stdlib.List.fold_right (fun h t -> Cons(h, t)) l Nil

let rec to_stdlib_list (l : 'a list) : 'a Stdlib.List.t =
  match l with
  | Nil -> []
  | Cons(h, t) -> h :: (to_stdlib_list t)


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

  | Concrete.Expression.BinOp {left; op; right; _} -> begin
      match op with
      | Concrete.BinaryOperator.Add ->
        Call(Attribute(translate_expr left, "__add__"), to_pyskel_list [translate_expr right])
      | _ -> failwith "BinOp not specified yet"
    end
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
  | Concrete.Statement.Assign {
      targets = Concrete.Expression.Attribute { value; attr; _} :: _;
      value = e; _} ->
    SAttrAssign(translate_expr value, Concrete.Identifier.to_string attr, translate_expr e)
  | Concrete.Statement.Delete {
      targets = Concrete.Expression.Name {id = x; _} :: _
    ; _} ->
    SDel(Concrete.Identifier.to_string x)
  | Concrete.Statement.Pass _ -> SPass
  | Concrete.Statement.Return {value = Some e; _} ->
    SReturn (translate_expr e)
  | Concrete.Statement.FunctionDef {
      decorator_list = [
        Concrete.Expression.Call {
          func = Concrete.Expression.Name {id = s; _};
          args = [Concrete.Expression.Constant {
              value = Concrete.Constant.String constructorName; _}]; _
        }
      ]; name = name; _
    } when Concrete.Identifier.to_string s = "pyskel_internal" ->
    SAssign (Concrete.Identifier.to_string name, InternalToken IntAdd)


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
  | Concrete.Statement.Raise {exc = Some expr; _} ->
    SRaise (translate_expr expr)
  | Concrete.Statement.Try {body; handlers; _} ->
    STry (to_pyskel_list @@ Stdlib.List.map translate_stmt body
         , translate_handler (Stdlib.List.hd handlers)
         )
  | _ -> failwith "statement not specified yet"

and translate_handler (h: Concrete.ExceptionHandler.t) : exn_handler =
  match h with
  | {type_ = Some e; body;_ } ->
    (* (translate_expr e, to_pyskel_list @@ Stdlib.List.map translate_stmt body) *)
    (translate_expr e, to_pyskel_list @@ Stdlib.List.map translate_stmt body)
  | _ -> failwith "exception handler not specified yet"

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
      (Stdlib.List.fold_left (fun s p -> s ^ p ^ ", ") "" @@ to_stdlib_list args)
      (Stdlib.List.fold_left (fun s p -> s ^ "'" ^ p ^ "'" ^ ", ") "" @@ to_stdlib_list locals)
  | Class(name, supers, _, dict) ->
    let supers_str =
      String.concat ", " @@ Stdlib.List.map (show_objn heap) @@ Stdlib.List.map (fun a -> fst @@ IMap.find a heap) @@ to_stdlib_list supers in
    Printf.sprintf "class %s (%s) %s" name supers_str (show_dict heap dict)
  | Inst addr ->
    let f = function Class (name, _, _, _) -> name | _ -> "NonClass" in

    Printf.sprintf "instance of %s" @@ f (fst @@ IMap.find addr heap)
  | Method (self, fun_) ->
    let (self_obj, _) = IMap.find self heap in
    let (fun_obj, _) = IMap.find fun_ heap in
    Printf.sprintf "<method %s of object <%s>>" (show_objn heap fun_obj) (show_objn heap self_obj);

  | _ -> Printf.sprintf "Unknown"


let show_flag heap flag =
  match flag with
  | Ret _ -> Printf.sprintf "Flag is %s\n" "Ret"
  | Brk -> Printf.sprintf "Flag is %s\n" "Brk"
  | Cont -> Printf.sprintf "Flag is %s\n" "Cont"
  | Exn exn ->
    let (objn, _) = IMap.find exn heap in
    Printf.sprintf "Flag is Exn:\n\t%s" (show_objn heap objn)



let eval_file_with_prelude builtins heap contents =
  (* Read Prelude *)
  (* Parse program *)
  let a = Parser.with_context (fun context ->
      Parser.Concrete.parse_module ~context contents
    ) in

  (* Check for parse error *)
  Result.iter_error
    (fun Parser.Error.{message; line; column; _} ->
       Printf.fprintf stderr "Syntax error at (line %d, column %d):\n\t%s\n" line column message;
       exit 1;
    ) a;

  (* Eval file with pyskel *)
  let ast = translate_ast (Result.get_ok a) in
  let fs = M.extract (eval_stmts ast) in
  builtins, M.extract (fs (builtins, heap))

let eval_file contents =
  let (builtins, heap) = M.extract @@ initializedHeap () in
  eval_file_with_prelude builtins
    { global_scope = initialEnv
    ; scope_heap = initialHeap
    ; heap = heap} contents
