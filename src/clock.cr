require "./lox_callable"

module Crylox
  class Clock < LoxCallable
    def arity
      0
    end

    def call(interpereter : Interpreter, arguments : Array(LiteralType)) : LiteralType
      Time.monotonic.milliseconds / 1000.0
    end

    def to_string
      "<native fn>"
    end
  end
end
