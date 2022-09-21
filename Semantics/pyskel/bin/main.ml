open Necromonads
open PyreAst

module Inst(M:MONAD) = struct
  module rec Types : sig
    include Pyskel.Bool_inst.TYPE
  end = Types

  module Spec : Pyskel.Bool.UNSPEC = struct
    include Pyskel.Bool.Unspec(M)(Types)
    include Pyskel.Bool_inst.Spec(M)
  end

  module Interpreter : Pyskel.Bool.INTERPRETER = Pyskel.Bool.MakeInterpreter(Spec)
end

module InterInst = Inst(Necromonads.ContPoly)

open InterInst.Interpreter

let translate_ast (m: Concrete.Module.t) : constant =
  match m with
  | {Concrete.Module.body =
       [Concrete.Statement.Expr
          {value = Concrete.Expression.Constant
               {value = Concrete.Constant.True; _}; _}]; _} ->
    True
  | {Concrete.Module.body =
       [Concrete.Statement.Expr
          {value = Concrete.Expression.Constant
               {value = Concrete.Constant.False; _}; _}]; _} ->
    False
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
  begin match M.extract (eval ast) with
    | True -> Printf.printf "Result is \"True\".\n"
    | False -> Printf.printf "Result is \"False\".\n"
    | None -> Printf.printf "Result is \"None\".\n"
    | NotImplemented -> Printf.printf "Result is \"NotImplemented\".\n"
  end;
