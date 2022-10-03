open Necromonads

module SMap = Map.Make(String)

module type TYPE = sig
  type id = string
  type envData
  type env = envData SMap.t
end

module Spec (M:MONAD) = struct
  let initialEnv = SMap.empty

  let getEnvData (e, id) =
    M.ret (SMap.find id e)
end
