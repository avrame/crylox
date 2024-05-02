require "./lox_callable"
require "./ast"

module Crylox
  class LoxFunction < LoxCallable
    def initialize(@declaration : Function, @closure : Environment)
    end

    def call(interpreter : Interpreter, arguments : Array(LiteralType)) : LiteralType
      environment = Environment.new(@closure)
      @declaration.params.each_with_index do |param, idx|
        environment.define(param.lexeme, arguments[idx])
      end
      begin
        interpreter.execute_block(@declaration.body, environment)
      rescue return_exception : ReturnException
        return return_exception.value
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
