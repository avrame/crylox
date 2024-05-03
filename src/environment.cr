require "./token"

module Crylox
  class Environment
    getter enclosing : Environment | Nil
    getter values = Hash(String, LiteralType).new

    def initialize
      @enclosing = nil
    end

    def initialize(enclosing : Environment)
      @enclosing = enclosing
    end

    def define(name : String, value : LiteralType)
      @values[name] = value
    end

    def ancestor(distance : Int32)
      environment = self
      i = 0
      while i < distance
        if environment.nil?
          raise Exception.new
        else
          environment = environment.enclosing
        end
        i += 1
      end
      environment
    end

    def get_at(distance : Int32, name : String)
      ancestor(distance).not_nil!.values[name]
    end

    def assign_at(distance : Int32, name : Token, value : LiteralType)
      ancestor(distance).not_nil!.values[name.lexeme] = value
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
