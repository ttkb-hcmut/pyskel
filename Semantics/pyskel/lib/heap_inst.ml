open Necromonads

module IMap = Map.Make(Int)

module type TYPE = sig
  type 'a heap_addr = int
  type 'a heap = 'a IMap.t * int
end

module Spec (M:MONAD) = struct
  let initialHeap = (IMap.empty, 0)

  let heapAlloc ((h, i), v) =
    M.ret (i, (IMap.add i v h, i + 1))

  let heapRead ((h, i), v) =
    M.ret (IMap.find v h, (h, i))

  let heapWrite ((h, i), a, v) =
    M.ret ((), (IMap.add a v h, i))

  let internal_addr_equal (x, y) =
    M.ret (x = y)

  (* Arbitrary *)
  let todoError = 42
end
