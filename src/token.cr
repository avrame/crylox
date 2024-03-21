module Crylox
  alias LiteralType = String | Char | Float64 | Nil | Bool

  enum TokenType
    # Single-character tokens.
    LEFT_PAREN
    RIGHT_PAREN
    LEFT_BRACE
    RIGHT_BRACE
    COMMA
    DOT
    MINUS
    PLUS
    SEMICOLON
    SLASH
    STAR

    # One or two character tokens.
    BANG
    BANG_EQUAL
    EQUAL
    EQUAL_EQUAL
    GREATER
    GREATER_EQUAL
    LESS
    LESS_EQUAL

    # Literals.
    IDENTIFIER
    STRING
    NUMBER

    # Keywords.
    AND
    CLASS
    ELSE
    FALSE
    FUN
    FOR
    IF
    NIL
    OR
    PRINT
    RETURN
    SUPER
    THIS
    TRUE
    VAR
    WHILE

    EOF
  end

  class Token
    property lexeme : String
    getter type : TokenType
    getter literal : LiteralType
    getter line : Int64

    def initialize(@type : TokenType, @lexeme : String, @literal : LiteralType, @line : Int64)
    end

    def to_s
      "type: #{@type}, lexeme: #{@lexeme}, literal: #{@literal}"
    end
  end
end
