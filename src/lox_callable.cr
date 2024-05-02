require "./interpreter"
require "./token"

module Crylox
  abstract class LoxCallable
    def call(interpreter : Interpreter, arguments : Array(LiteralType)) : LiteralType
    end

    def arity() : Int
      0
    end
  end
end
