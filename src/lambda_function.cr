require "./lox_callable"
require "./ast"

module Crylox
  class LambdaFunction < LoxFunction
    def initialize(@declaration : Lambda, @closure : Environment)
    end

    def to_string
      "<fn>"
    end
  end
end
