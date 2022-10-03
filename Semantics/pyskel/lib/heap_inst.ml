open Necromonads

module IMap = Map.Make(Int)

module type TYPE = sig
  type value
  type addr = int
  type heap = value IMap.t * int
end

module Spec (M:MONAD) = struct
  let addr_true = 0
  let addr_false = 1
  let addr_none = 2
  let addr_notImplemented = 3

  let initialHeap = (IMap.empty, 4)

  let heapAlloc ((h, i), v) =
    M.ret (i, (IMap.add i v h, i + 1))

  let heapRead ((h, i), v) =
    M.ret (IMap.find v h, (h, i))

  let heapWrite ((h, i), a, v) =
    M.ret ((), (IMap.add a v h, i))

  (* Arbitrary *)
  let unboundLocalError = 42
end
