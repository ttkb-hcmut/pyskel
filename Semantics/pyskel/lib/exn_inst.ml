open Necromonads

module type TYPE = sig
end

module Spec (M:MONAD) = struct
  let _BaseException = "BaseException"
  let _Exception = "Exception"
  let _NameError = "NameError"
  let _UnboundLocalError = "NameError"
end
