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
      initializer = find_method("init")
      if !initializer.nil?
        initializer.bind(instance).call(interpreter, arguments)
      end
      instance
    end

    def arity
      initializer = find_method("init")
      if initializer.nil?
        return 0
      end
      initializer.arity()
    end
  end
end
