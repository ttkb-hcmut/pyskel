open Necromonads

module SMap = Map.Make(String)

module type TYPE = sig
  type id = string
  type 'a maybe
  type addr
  type env = (addr maybe) SMap.t
end

module Spec (M:MONAD) = struct
  let initialEnv = SMap.empty

  let getEnvData (e, id) =
    M.ret (SMap.find id e)

  let envWrite (e, id, addr) =
    M.ret (SMap.add id addr e)
end
