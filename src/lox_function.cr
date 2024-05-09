require "./lox_callable"
require "./ast"

module Crylox
  class LoxFunction < LoxCallable
    def initialize(@declaration : Function | Lambda, @closure : Environment, @is_initializer : Bool)
    end

    def bind(instance : LoxInstance)
      environment = Environment.new(@closure)
      environment.define("this", instance)
      return LoxFunction.new(@declaration, environment, @is_initializer)
    end

    def call(interpreter : Interpreter, arguments : Array(LiteralType)) : LiteralType
      environment = Environment.new(@closure)

      @declaration.params.each_with_index do |param, idx|
        environment.define(param.lexeme, arguments[idx])
      end

      begin
        interpreter.execute_block(@declaration.body, environment)
      rescue return_exception : ReturnException
        if @is_initializer
          return @closure.get_at(0, "this")
        end
        return return_exception.value
      end

      if @is_initializer
        return @closure.get_at(0, "this")
      end

      nil
    end

    def arity
      @declaration.params.size
    end

    def to_string
      "<fn #{@declaration.name.lexeme}>"
    end
  end
end
