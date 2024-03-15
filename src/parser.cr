require "./token"
require "./ast"

module Crylox
  class Parser
    @current : Int64 = 0

    def initialize(@tokens : Array(Token))
    end

    def parse
      begin
        return expression()
      rescue
        return nil
      end
    end

    def expression
      return equality()
    end

    def equality
      expr = comparison()

      while match(:BANG_EQUAL, :EQUAL_EQUAL)
        operator = previous()
        right = comparison()
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    def comparison : Expr
      expr = term()

      while match(:GREATER, :GREATER_EQUAL, :LESS, :LESS_EQUAL)
        operator = previous()
        right = term()
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    def term : Expr
      expr = factor()

      while match(:MINUS, :PLUS)
        operator = previous()
        right = factor()
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    def factor : Expr
      expr = unary()

      while match(:SLASH, :STAR)
        operator = previous()
        right = unary()
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    def unary : Expr
      if match(:BANG, :MINUS)
        operator = previous()
        right = unary()
        return Unary.new(operator, right)
      end

      primary()
    end

    def primary : Expr
      if match(:FALSE)
        return Literal.new(false)
      end

      if match(:TRUE)
        return Literal.new(true)
      end

      if match(:NIL)
        return Literal.new(nil)
      end

      if match(:NUMBER, :STRING)
        return Literal.new(previous().literal)
      end

      if match(:LEFT_PAREN)
        expr = expression()
        consume(:RIGHT_PAREN, "Expect ')' after expression.")
        return Grouping.new(expr)
      end

      raise error(peek(), "Expect Expression")
    end

    def consume(type : TokenType, message : String)
      if check(type)
        return advance()
      end

      error(peek(), message)
    end

    def error(token : Token, message : String)
      Lox.error(token, message)
      return ParseException.new
    end

    def synchronize
      advance()
      while !is_at_end()
        if previous().type == :SEMICOLON
          return
        end

        case peek().type
        when :CLASS | :FUN | :VAR | :FOR | :IF | :WHILE | :PRINT | :RETURN
          return
        end

        advance()
      end
    end

    def match(*types : TokenType) : Bool
      types.each do |type|
        if check(type)
          advance()
          return true
        end
      end

      false
    end

    def check(type : TokenType)
      if is_at_end()
        return false
      end
      return peek().type == type
    end

    def advance : Token
      if !is_at_end()
        @current += 1
      end
      previous()
    end

    def is_at_end
      return peek().type == :EOF
    end

    def peek : Token
      return @tokens[@current]
    end

    def previous : Token
      return @tokens[@current - 1]
    end
  end

  class ParseException < Exception
  end
end
