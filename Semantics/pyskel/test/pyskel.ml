open Pyskel.Utils.InterInst.Interpreter
module Utils = Pyskel.Utils

let test_file (builtins, heap) file_name python =
  Printf.printf "\n\n######\n";
  Printf.printf "## %s\n" file_name;
  Printf.printf "##\n";
  (* Open file and get contents *)
  let file = open_in file_name in

  (* Get the things to print *)
  let first_line = input_line file in
  let thing_to_print = (String.sub first_line 1 (String.length first_line - 1)) in
  let contents = really_input_string file (in_channel_length file - String.length first_line - 1) in
  close_in file;

  let (_, result) = Utils.eval_file_with_prelude builtins heap contents in

  (* Eval file with pyskel *)
  match result with
  | (Flag f, {heap; _}) ->
    Printf.printf "Error, result is not Cur.\n";
    Printf.printf "%s" @@ Utils.show_flag (fst heap) f
  | (Cur (), {global_scope = env; heap = (heap, _); _}) -> begin
      let module SMap = Map.Make(String) in
      let module IMap = Map.Make(Int) in
      match SMap.find_opt "__result__" env with
      | None -> failwith "var `__result__` is not defined."
      | Some addr -> begin
          (* Read the objN from heap *)
          let objn = fst @@ IMap.find addr heap in
          Printf.printf " Pyskel: %s\n" @@ Utils.show_objn heap objn;
        end
    end;

  (* Eval file with python *)
  let tmp_file = Filename.temp_file "" ".out" in
  Printf.printf "CPython: ";
  ignore @@ Sys.command @@ Printf.sprintf
    "mktemp | xargs -I {} sh -c \"cat %s > {}; echo 'print(%s)' >> {} && %s {}\" > %s"
    file_name thing_to_print python tmp_file;
  let reader = open_in tmp_file in
  let rec loop () = Printf.printf "%s" (input_line reader) ; loop () in
  try loop () with _ -> close_in reader


let test_dir python_path data dir =
  if Sys.is_directory dir then begin
    let files = Sys.readdir dir in
    Array.iter (fun file -> test_file data (dir ^ Filename.dir_sep ^ file) python_path) files;
  end

let _ =
  let python_path =
      let config_file = open_in "python_path" in
      let python_path = really_input_string config_file (in_channel_length config_file - 1) in
      close_in config_file; python_path in
  Printf.printf "\"%s\"" python_path;
  (* Read file name from command line args *)
  let test_directory = "python_files" in

  if Stdlib.not (Sys.is_directory test_directory) then
      Printf.fprintf stderr "%s is not a directory" test_directory;
  Sys.chdir test_directory;

  let prelude = open_in "prelude.py" in
  let contents = really_input_string prelude (in_channel_length prelude) in

  let (builtins, (result, heap)) = Utils.eval_file contents in
  close_in prelude;
  begin
    match result with
    | Utils.InterInst.Interpreter.Cur _ -> ()
    | _ -> failwith "Evaluation of prelude failed !"
  end;

  let subdirs = Sys.readdir "." in
  Array.iter (test_dir python_path (builtins, heap)) subdirs
