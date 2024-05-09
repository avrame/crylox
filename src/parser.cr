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
        if match :CLASS
          return class_declaration()
        end
        if match :FUN
          return function("function")
        end
        if match :VAR
          return var_declaration()
        end
        return statement()
      rescue exception : ParseException
        synchronize()
        return nil
      end
    end

    def class_declaration
      name = consume :IDENTIFIER, "Expect class name."
      consume :LEFT_BRACE, "Expect '{' before class body."

      methods = [] of Function
      while !check(:RIGHT_BRACE) && !is_at_end
        methods << function("method")
      end

      consume :RIGHT_BRACE, "Expect '}' after class body."
      return Class.new(name, methods)
    end

    def statement
      if match :FOR
        return for_statement()
      end

      if match :IF
        return if_statement()
      end

      if match :PRINT
        return print_statement()
      end

      if match :RETURN
        return return_statement()
      end

      if match :WHILE
        return while_statement()
      end

      if match :BREAK
        return break_statement()
      end

      if match :LEFT_BRACE
        return Block.new(block())
      end

      expression_statement()
    end

    def for_statement
      consume :LEFT_PAREN, "Expect '(' after 'for'"

      initializer : Stmt | Nil
      if match :SEMICOLON
        initializer = nil
      elsif match :VAR
        initializer = var_declaration()
      else
        initializer = expression_statement()
      end

      condition : Expr | Nil = nil
      if !check :SEMICOLON
        condition = expression()
      end
      consume :SEMICOLON, "Expect ';' after loop condition."

      increment : Expr | Nil = nil
      if !check :SEMICOLON
        increment = expression()
      end
      consume :RIGHT_PAREN, "Expect ')' after for clauses."

      body = statement()

      if !increment.nil?
        body = Block.new([body, Expression.new(increment)] of Stmt)
      end

      if condition.nil?
        condition = Literal.new(true)
      end
      body = While.new(condition, body)

      if !initializer.nil?
        body = Block.new([initializer, body])
      end

      body
    end

    def if_statement
      consume :LEFT_PAREN, "Expect '(' after 'if'."
      condition = expression()
      consume :RIGHT_PAREN, "Expect ')' after if condition."

      then_branch = statement()
      else_branch = nil
      if match :ELSE
        else_branch = statement()
      end

      If.new(condition, then_branch, else_branch)
    end

    def print_statement
      value = expression()
      consume :SEMICOLON, "Expect ';' after value."
      Print.new(value)
    end

    def return_statement
      keyword = previous()
      value = nil
      if !check :SEMICOLON
        value = expression()
      end
      consume :SEMICOLON, "Expect ';' after return value."
      Return.new(keyword, value)
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

    def while_statement
      consume :LEFT_PAREN, "Expect '(' after 'while'"
      condition = expression()
      consume :RIGHT_PAREN, "Expect ')' after condition."
      body = statement()
      While.new(condition, body)
    end

    def break_statement
      keyword = previous()
      consume :SEMICOLON, "Expect ';' after break statement."
      Break.new(keyword)
    end

    def expression_statement
      expr = expression()
      consume :SEMICOLON, "Expect ';' after expression."
      Expression.new(expr)
    end

    def function(kind : String)
      name = consume :IDENTIFIER, "Expect #{kind} name."
      consume :LEFT_PAREN, "Expect '(' after #{kind} name."
      parameters = parse_parameters()
      consume :RIGHT_PAREN, "Expect ')' after parameters."
      consume :LEFT_BRACE, "Expect '{' before #{kind} body."
      body = block()
      Function.new(name, parameters, body)
    end

    def lambda
      consume :LEFT_PAREN, "Expect '(' after fn."
      parameters = parse_parameters()
      consume :RIGHT_PAREN, "Expect ')' after parameters."
      consume :LEFT_BRACE, "Expect '{' before fn body."
      body = block()
      Lambda.new(parameters, body)
    end

    def parse_parameters
      parameters = [] of Token
      if !check :RIGHT_PAREN
        loop do
          if parameters.size >= 255
            error(peek(), "Can't have more than 255 parameters.")
          end
          parameters << consume :IDENTIFIER, "Expect parameter name."
          break unless match :COMMA
        end
      end
      parameters
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
      expr = or()

      if match :EQUAL
        equals : Token = previous()
        value : Expr = assignment()

        if expr.is_a? Variable
          name : Token = expr.name
          return Assign.new(name, value)
        elsif expr.is_a? Get
          return Set.new(expr.object, expr.name, value)
        end

        error(equals, "Invalid assignment target.")
      end

      expr
    end

    def or
      expr = and()

      while match :OR
        operator = previous()
        right = and()
        expr = Logical.new(expr, operator, right)
      end

      expr
    end

    def and
      expr = equality()

      while match :AND
        operator = previous()
        right = equality()
        expr = Logical.new(expr, operator, right)
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

      call()
    end

    def call
      expr = primary()
      loop do
        if match :LEFT_PAREN
          expr = finish_call(expr)
        elsif match :DOT
          name = consume :IDENTIFIER, "Expect property name after '.'."
          expr = Get.new(expr, name)
        else
          break
        end
      end
      expr
    end

    def finish_call(callee : Expr)
      arguments = [] of Expr

      if !check :RIGHT_PAREN
        loop do
          if arguments.size >= 255
            error peek(), "Can't have more than 255 arguments."
          end
          arguments << expression()
          break if !match :COMMA
        end
      end

      paren = consume :RIGHT_PAREN, "Expect ')' after arguments."
      Call.new(callee, paren, arguments)
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

      if match :THIS
        return This.new(previous())
      end

      if match :IDENTIFIER
        return Variable.new(previous())
      end

      if match :FUN
        return lambda()
      end

      raise error peek(), "Expect Expression"
    end

    def consume(type : TokenType, message : String)
      if check(type)
        return advance()
      end

      raise error peek(), message
    end

    def error(token : Token, message : String)
      Lox.error token, message
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
