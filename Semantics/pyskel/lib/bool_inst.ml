open Necromonads

module type TYPE = sig
  type internal_bool = bool
end

module Spec (M:MONAD) = struct
  let internal_if (b, x, y) =
    M.ret @@ if b then x else y

  let internal_eq (a, b) =
    M.ret @@ (a = b)
end
