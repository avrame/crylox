require "./token"

module Crylox
  class Environment
    @enclosing : Environment | Nil
    @values = Hash(String, LiteralType).new

    def initialize
      @enclosing = nil
    end

    def initialize(enclosing : Environment)
      @enclosing = enclosing
    end

    def define(name : String, value : LiteralType)
      @values[name] = value
    end

    def get(name : Token) : Object
      if @values.has_key? name.lexeme
        return @values[name.lexeme]
      end

      if !@enclosing.nil?
        return @enclosing.not_nil!.get(name)
      end

      raise RuntimeException.new name, "Undefined variable '#{name.lexeme}'."
    end

    def assign(name : Token, value : LiteralType)
      if @values.has_key? name.lexeme
        @values[name.lexeme] = value
        return
      end

      if !@enclosing.nil?
        @enclosing.not_nil!.assign(name, value)
        return
      end

      raise RuntimeException.new name, "Undefined variable '#{name.lexeme}'."
    end
  end
end
