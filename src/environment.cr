require "./token"

module Crylox
  class Environment
    @values = Hash(String, LiteralType).new

    def define(name : String, value : LiteralType)
      @values[name] = value
    end

    def get(name : Token) : Object
      if @values.has_key? name.lexeme
        return @values[name.lexeme]
      end

      raise RuntimeException.new name, "Undefined variable'#{name.lexeme}'."
    end
  end
end
