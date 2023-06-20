open Necromonads
module SMap = Map.Make(String)

module type TYPE = sig
  type id = string
  type 'a map = 'a SMap.t
end

module Spec (M:MONAD) = struct
  let map_empty = SMap.empty

  let type_id = "type"
  let function_id = "function"
  let method_id = "method"
  let list_id = "list"
  let tuple_id = "tuple"
  let notImplementedType_id = "NotImplementedType"
  let noneType_id = "NoneType"
  let str_id = "str"
  let int_id = "int"
  let bool_id = "bool"
  let __init__ = "__init__"

  let internal_map_elem (s, m) =
    M.ret @@ SMap.mem s m

  let map_find (s, m) =
    M.ret @@ SMap.find s m

  let map_insert (s, v, m) =
    M.ret @@ SMap.add s v m

  let map_del (s, m) =
    M.ret @@ SMap.remove s m
end
