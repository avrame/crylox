require "./token"
require "./ast"

module Crylox
  class Parser
    @current : Int64 = 0

    def initialize(@tokens : Array(Token))
    end

    def parse
      statements = [] of Stmt | Nil
      while !is_at_end
        statements << declaration()
      end
      statements
    end

    def expression
      return assignment()
    end

    def declaration
      begin
        if match :VAR
          return var_declaration()
        end
        return statement()
      rescue exception : ParseException
        synchronize()
        return nil
      end
    end

    def statement
      if match :PRINT
        return print_statement()
      end

      if match :LEFT_BRACE
        return Block.new(block())
      end

      expression_statement()
    end

    def print_statement
      value = expression()
      consume :SEMICOLON, "Expect ';' after value."
      Print.new(value)
    end

    def var_declaration
      name : Token = consume :IDENTIFIER, "Expect variable name."
      initializer = nil
      if match :EQUAL
        initializer = expression()
      end
      consume :SEMICOLON, "Expect ';' after variable declaration."
      Var.new(name, initializer)
    end

    def expression_statement
      expr = expression()
      consume :SEMICOLON, "Expect ';' after expression."
      Expression.new(expr)
    end

    def block
      statements = [] of Stmt

      while !check(:RIGHT_BRACE) && !is_at_end
        declaration = declaration()
        if !declaration.nil?
          statements << declaration.not_nil!
        end
      end

      consume :RIGHT_BRACE, "Expect '}' after block."
      statements
    end

    def assignment
      expr = equality()

      if match :EQUAL
        equals : Token = previous()
        value : Expr = assignment()

        if expr.is_a? Variable
          name : Token = expr.name
          return Assign.new(name, value)
        end

        error(equals, "Invalid assignment target.")
      end

      expr
    end

    def equality
      expr = comparison()

      while match :BANG_EQUAL, :EQUAL_EQUAL
        operator = previous()
        right = comparison()
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    def comparison : Expr
      expr = term()

      while match :GREATER, :GREATER_EQUAL, :LESS, :LESS_EQUAL
        operator = previous()
        right = term()
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    def term : Expr
      expr = factor()

      while match :MINUS, :PLUS
        operator = previous()
        right = factor()
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    def factor : Expr
      expr = unary()

      while match :SLASH, :STAR
        operator = previous()
        right = unary()
        expr = Binary.new(expr, operator, right)
      end

      expr
    end

    def unary : Expr
      if match :BANG, :MINUS
        operator = previous()
        right = unary()
        return Unary.new(operator, right)
      end

      primary()
    end

    def primary : Expr
      if match :FALSE
        return Literal.new(false)
      end

      if match :TRUE
        return Literal.new(true)
      end

      if match :NIL
        return Literal.new(nil)
      end

      if match :NUMBER, :STRING
        return Literal.new(previous().literal)
      end

      if match :LEFT_PAREN
        expr = expression()
        consume(:RIGHT_PAREN, "Expect ')' after expression.")
        return Grouping.new(expr)
      end

      if match :IDENTIFIER
        return Variable.new(previous())
      end

      raise error(peek(), "Expect Expression")
    end

    def consume(type : TokenType, message : String)
      if check(type)
        return advance()
      end

      raise error(peek(), message)
    end

    def error(token : Token, message : String)
      Lox.error(token, message)
      return ParseException.new
    end

    def synchronize
      advance()
      while !is_at_end
        if previous().type == TokenType
          :SEMICOLON
          return
        end

        case peek().type
        when TokenType::CLASS | TokenType::FUN | TokenType::VAR | TokenType::FOR | TokenType::IF | TokenType::WHILE | TokenType::PRINT | TokenType::RETURN
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
      if is_at_end
        return false
      end
      return peek().type == type
    end

    def advance : Token
      if !is_at_end
        @current += 1
      end
      previous()
    end

    def is_at_end
      return peek().type == TokenType::EOF
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
