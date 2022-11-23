open Necromonads

module IMap = Map.Make(Int)

module type TYPE = sig
  type pythonInt = int
  type pythonString = string

  type env = unit
end

module Spec(M:MONAD) = struct
  exception NotImplemented of string
  let debug () = M.ret @@ print_endline "debug"
end
