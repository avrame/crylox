module Crylox
  class LoxInstance
    @fields = Hash(String, LiteralType).new

    def initialize(@klass : LoxClass)
    end

    def get(name : Token)
      if @fields.has_key? name.lexeme
        return @fields[name.lexeme]
      end

      method = @klass.find_method(name.lexeme)
      if !method.nil?
        return method.bind(self)
      end

      raise RuntimeException.new name, "Undefined property '#{name.lexeme}'."
    end

    def set(name : Token, value : LiteralType)
      @fields[name.lexeme] = value
    end

    def to_string
      @klass.name + " instance"
    end
  end
end
