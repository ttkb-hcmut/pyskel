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


let _ =
  match M.extract (eval (True)) with
  | True -> Printf.printf "All is ok.\n"


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

  (* Check result *)
  begin
    match (Result.get_ok a) with
    | { Concrete.Module.body = [Concrete.Statement.Expr { value = Concrete.Expression.Constant { value = Concrete.Constant.True; _ }; _}]; _}
      -> Printf.printf "I parsed \"True\".\n"
    | _ ->
      Printf.printf "I did not parse \"True\".\n"
  end

  (* TODO: Make a convertion module (at least a function) from
     PyreAst.Concrete.Module to the subset of specified python semantics *)
