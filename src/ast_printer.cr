require "./ast"
require "./token"

module Crylox
  # expression = Binary.new(
  #   Unary.new(
  #     Token.new(TokenType::MINUS, "-", nil, 1),
  #     Literal.new(123)
  #   ),
  #   Token.new(TokenType::STAR, "*", nil, 1),
  #   Grouping.new(Literal.new(45.67))
  # )

  # puts AstPrinter.new.print(expression)

  class AstPrinter < Visitor(String)
    def print(expr : Expr)
      expr.accept(self)
    end

    def visit_binary_expr(expr : Binary)
      parenthesize(expr.operator.lexeme, expr.left, expr.right)
    end

    def visit_grouping_expr(expr : Grouping)
      parenthesize("group", expr.expression)
    end

    def visit_literal_expr(expr : Literal)
      if expr.value.nil?
        return "nil"
      else
        return expr.value
      end
    end

    def visit_unary_expr(expr : Unary)
      parenthesize(expr.operator.lexeme, expr.right)
    end

    def parenthesize(name : String, *exprs) : String
      str = String.build do |str|
        str << "(#{name}"
        exprs.each do |expr|
          str << " "
          str << expr.accept(self)
        end
        str << ")"
      end

      str
    end
  end
end
