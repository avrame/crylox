require "./lox_instance"

module Crylox
  class LoxClass < LoxCallable
    def initialize(@name : String, @methods : Hash(String, LoxFunction))
    end

    def find_method(name : String)
      if @methods.has_key? name
        return @methods[name]
      end

      nil
    end

    def to_string
      @name
    end

    def call(interpreter : Interpreter, arguments : Array(LiteralType))
      instance = LoxInstance.new(self)
      instance
    end

    def arity
      0
    end
  end
end
