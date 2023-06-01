require "./token_type"

class Token
  def initialize(@type : TokenType, @lexeme : String, @literal : String | Float64 | Nil, @line : Int64)
  end

  def to_s()
    "type: #{@type}, lexeme: #{@lexeme}, literal: #{@literal}"
  end
end
