open Necromonads

module IMap = Map.Make(Int)

module type TYPE = sig
  type pythonInt = Int.t
  type pythonFloat = float
  type pythonString = string

  type env = unit
end

module Spec(M:MONAD) = struct
  exception NotImplemented of string
end
