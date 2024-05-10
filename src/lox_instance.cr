module Crylox
  class LoxInstance
    @fields = Hash(String, LiteralType).new

    def initialize(@class : LoxClass)
    end

    def get(name : Token)
      if @fields.has_key? name.lexeme
        return @fields[name.lexeme]
      end

      method = @class.find_method(name.lexeme)
      if !method.nil?
        return method.bind(self)
      end

      raise RuntimeException.new name, "Undefined property '#{name.lexeme}'."
    end

    def set(name : Token, value : LiteralType)
      @fields[name.lexeme] = value
    end

    def to_string
      @class.name + " instance"
    end
  end
end
