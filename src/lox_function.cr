require "./lox_callable"
require "./ast"

module Crylox
  class LoxFunction < LoxCallable
    @declaration : Function

    def initialize(@declaration : Function)
    end

    def call(interpreter : Interpreter, arguments : Array(LiteralType)) : LiteralType
      environment = Environment.new(interpreter.globals)
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
