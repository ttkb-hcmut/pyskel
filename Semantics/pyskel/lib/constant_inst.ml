open Necromonads

module IMap = Map.Make(Int)

module type TYPE = sig
  type python_int = int
  type python_string = string

  type env = unit
end

module Spec(M:MONAD) = struct
  exception NotImplemented of string
  let debug () = M.ret @@ print_endline "debug"
end
