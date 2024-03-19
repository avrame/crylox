require "./ast"
require "./token"

module Crylox
  class Interpreter < Visitor(Object)
    def visit_literal_expr(expr : Literal)
      expr.value
    end

    def visit_unary_expr(expr : Unary)
      right : Object = evaluate(expr.right)

      case expr.operator.type
      when :MINUS
        return -right
      when :BANG
        return !is_truthy(right)
      end

      nil
    end

    def is_truthy?(object : Object)
      case object
      when .nil?
        return false
      when .is_a?(Bool)
        return Object
      end
    end

    def visit_grouping_expr(expr : Grouping)
      evaluate(expr.expression)
    end

    def evaluate(expr : Expression)
      expr.accept(this)
    end

    def visit_binary_expr(expr : Binary)
      left : Float64 = evaluate(expr.left)
      right : Float64 = evaluate(expr.right)

      case expr.operator.type
      when :MINUS
        return left - right
      when :PLUS
        return left + right
      when :SLASH
        return left / right
      when :STAR
        return left * right
      when :GREATER
        return left > right
      when :GREATER_EQUAL
        return left >= right
      when :LESS
        return left < right
      when :LESS_EQUAL
        return left <= right
      when :BANG_EQUAL
        return !is_equal(left, right)
      when :EQUAL_EQUAL
        return is_equal(left, right)
      end

      nil
    end

    def is_equal(a : Object, b : Object)
      if a.nil? && b.nil?
        return true
      end
      if a.nil?
        return false
      end

      return a == b
    end
  end
end
