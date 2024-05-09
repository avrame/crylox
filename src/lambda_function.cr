require "./lox_callable"
require "./ast"

module Crylox
  class LambdaFunction < LoxFunction
    def initialize(@declaration : Lambda, @closure : Environment, @is_initializer : Bool)
    end

    def to_string
      "<fn>"
    end
  end
end
