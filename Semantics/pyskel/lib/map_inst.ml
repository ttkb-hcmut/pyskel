open Necromonads
module SMap = Map.Make(String)

module type TYPE = sig
  type id = string
  type 'a map = 'a SMap.t
end

module Spec (M:MONAD) = struct
  let map_empty = SMap.empty
  type pbool = PFalse | PTrue

  let map_elem (s, m) =
    M.ret @@
    match SMap.mem s m with
    | false -> PFalse
    | true -> PTrue

  let map_find (s, m) =
    M.ret @@ SMap.find s m

  let map_insert (s, v, m) =
    M.ret @@ SMap.add s v m

  let map_del (s, m) =
    M.ret @@ SMap.remove s m
end
