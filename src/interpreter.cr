require "./ast"
require "./token"
require "./crylox"
require "./runtime_exception"

module Crylox
  class Interpreter
    include ExprVisitor(Object)
    include StmtVisitor(Nil)

    def interpret(statements : Array(Stmt))
      begin
        statements.each do |statement|
          execute(statement)
        end
      rescue exception : RuntimeException
        Lox.runtime_exception(exception)
      end
    end

    def visit_literal_expr(expr : Literal)
      expr.value
    end

    def visit_unary_expr(expr : Unary)
      right = evaluate(expr.right)

      case expr.operator.type
      when :MINUS
        check_number_operand(expr.operator, right)
        return -right.as(Float64)
      when :BANG
        return !is_truthy?(right)
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

    def evaluate(expr : Expr)
      expr.accept(self)
    end

    def execute(stmt : Stmt)
      stmt.accept(self)
    end

    def visit_expression_stmt(stmt : Expression)
      evaluate(stmt.expression)
    end

    def visit_print_stmt(stmt : Print)
      value = evaluate(stmt.expression)
      puts stringify(value)
    end

    def visit_binary_expr(expr : Binary)
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.operator.type
      when TokenType::MINUS
        check_number_operands(expr.operator, left, right)
        return left.as(Float64) - right.as(Float64)
      when TokenType::PLUS
        if left.is_a? Float64 && right.is_a? Float64
          return left + right
        end
        if left.is_a? String && right.is_a? String
          return left + right
        end
        if left.is_a? String
          return left + stringify(right)
        end
        if right.is_a? String
          return stringify(left) + right
        end
        raise RuntimeException.new expr.operator, "Invalid Operands for + operator"
      when TokenType::SLASH
        check_number_operands(expr.operator, left, right)
        if right == 0
          raise RuntimeException.new expr.operator, "Attempted to divide by zero"
        end
        return left.as(Float64) / right.as(Float64)
      when TokenType::STAR
        check_number_operands(expr.operator, left, right)
        return left.as(Float64) * right.as(Float64)
      when TokenType::GREATER
        check_number_operands(expr.operator, left, right)
        return left.as(Float64) > right.as(Float64)
      when TokenType::GREATER_EQUAL
        check_number_operands(expr.operator, left, right)
        return left.as(Float64) >= right.as(Float64)
      when TokenType::LESS
        check_number_operands(expr.operator, left, right)
        return left.as(Float64) < right.as(Float64)
      when TokenType::LESS_EQUAL
        check_number_operands(expr.operator, left, right)
        return left.as(Float64) <= right.as(Float64)
      when TokenType::BANG_EQUAL
        return !is_equal(left, right)
      when TokenType::EQUAL_EQUAL
        return is_equal(left, right)
      end

      nil
    end

    def is_equal(a : Object, b : Object)
      if a.nil? && b.nil?
        return true
      end
      if a.nil? || b.nil?
        return false
      end

      return a == b
    end

    def check_number_operand(operator : Token, operand : Object)
      if operand.is_a? Float64
        return
      end
      raise RuntimeException.new operator, "Operand must be a number."
    end

    def check_number_operands(operator : Token, left : Object, right : Object)
      if left.is_a? Float64 && right.is_a? Float64
        return
      end
      raise RuntimeException.new operator, "Operands must be numbers."
    end

    def stringify(object)
      if object.nil?
        return "nil"
      end

      if object.is_a? Float64
        text = object.to_s
        if text.ends_with? ".0"
          text = text[0..-3]
        end
        return text
      end

      return object.to_s
    end
  end
end
