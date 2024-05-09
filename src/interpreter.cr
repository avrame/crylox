require "./ast"
require "./token"
require "./crylox"
require "./runtime_exception"
require "./environment"
require "./lox_callable"
require "./lox_function"
require "./lox_class"
require "./lambda_function"
require "./clock"

module Crylox
  class Interpreter
    getter globals : Environment = Environment.new
    @locals = Hash(Expr, Int32).new

    def initialize
      @environment = @globals
      @globals.define("clock", Clock.new)
    end

    def interpret(statements : Array(Stmt | Nil), is_repl = false)
      begin
        statements.each do |statement|
          if is_repl && statement.is_a? Expression
            puts stringify(evaluate(statement.expression))
          end
          execute(statement)
        end
      rescue exception : RuntimeException
        Lox.runtime_exception(exception)
      rescue exception : NilException
        Lox.error(1, "Statement is nil")
      end
    end

    def visit_literal_expr(expr : Literal)
      expr.value
    end

    def visit_logical_expr(expr : Logical)
      left = evaluate(expr.left)

      if expr.operator.type == TokenType::OR
        if is_truthy?(left)
          return left
        end
      else
        if !is_truthy?(left)
          return left
        end
      end

      evaluate(expr.right)
    end

    def visit_set_expr(expr : Expr)
      object = evaluate(expr.object)

      if !object.is_a? LoxInstance
        raise RuntimeException.new expr.name, "Only instances have fields."
      end

      value = evaluate(expr.value)
      object.set(expr.name, value)
      value
    end

    def visit_this_expr(expr : This)
      look_up_variable(expr.keyword, expr)
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

    def visit_variable_expr(expr : Variable)
      look_up_variable(expr.name, expr)
    end

    def look_up_variable(name : Token, expr : Expr)
      distance = @locals[expr]?
      if !distance.nil?
        return @environment.get_at(distance, name.lexeme)
      else
        return globals.get(name)
      end
    end

    def is_truthy?(object : Object)
      case object
      when .nil?
        return false
      when .is_a?(Bool)
        return object
      end
    end

    def visit_grouping_expr(expr : Grouping)
      evaluate(expr.expression)
    end

    def evaluate(expr : Expr)
      expr.accept(self)
    end

    def execute(stmt : Stmt | Nil)
      if !stmt.nil?
        stmt.accept(self)
      else
        raise NilException.new
      end
    end

    def resolve(expr : Expr, depth : Int)
      @locals[expr] = depth
    end

    def visit_block_stmt(stmt : Block)
      execute_block(stmt.statements, Environment.new(@environment))
      nil
    end

    def visit_class_stmt(stmt : Class)
      @environment.define(stmt.name.lexeme, nil)

      methods = Hash(String, LoxFunction).new
      stmt.methods.each do |method|
        function = LoxFunction.new(method, @environment, method.name == "init")
        methods[method.name.lexeme] = function
      end

      klass = LoxClass.new(stmt.name.lexeme, methods)
      @environment.assign(stmt.name, klass)
      nil
    end

    def execute_block(statements : Array(Stmt), environment : Environment)
      previous = @environment
      begin
        @environment = environment
        statements.each do |statement|
          execute(statement)
        end
      ensure
        @environment = previous
      end
    end

    def visit_expression_stmt(stmt : Expression)
      evaluate(stmt.expression)
      nil
    end

    def visit_function_stmt(stmt : Function)
      function = LoxFunction.new(stmt, @environment, false)
      @environment.define(stmt.name.lexeme, function)
      nil
    end

    def visit_if_stmt(stmt : If)
      if is_truthy?(evaluate(stmt.condition))
        execute(stmt.then_branch)
      elsif !stmt.else_branch.nil?
        execute(stmt.else_branch)
      end
      nil
    end

    def visit_print_stmt(stmt : Print)
      value = evaluate(stmt.expression.not_nil!)
      puts stringify(value)
      nil
    end

    def visit_return_stmt(stmt : Return)
      value = nil
      if !stmt.value.nil?
        value = evaluate(stmt.value.not_nil!)
      end
      raise ReturnException.new(value)
    end

    def visit_var_stmt(stmt : Var)
      value = nil
      if !stmt.initializer.nil?
        value = evaluate(stmt.initializer.not_nil!)
      end
      @environment.define(stmt.name.lexeme, value)
      nil
    end

    def visit_while_stmt(stmt : While)
      while is_truthy? evaluate(stmt.condition)
        begin
          execute(stmt.body)
        rescue break_exception : BreakException
          break
        end
      end
      nil
    end

    def visit_break_stmt(stmt : Break)
      raise BreakException.new
    end

    def visit_assign_expr(expr : Assign)
      value = evaluate(expr.value)

      distance = @locals[expr]?
      if !distance.nil?
        @environment.assign_at(distance, expr.name, value)
      else
        @globals.assign(expr.name, value)
      end

      value
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

    def visit_lambda_expr(expr : Lambda)
      LambdaFunction.new(expr, @environment, false)
    end

    def visit_call_expr(expr : Call)
      callee = evaluate(expr.callee)

      arguments = [] of LiteralType
      expr.arguments.each do |argument|
        arguments << evaluate(argument)
      end

      if !callee.is_a? LoxCallable
        raise RuntimeException.new expr.paren, "Can only call functions and classes."
      end

      function = callee.as(LoxCallable)
      if arguments.size != function.arity
        raise RuntimeException.new expr.paren, "Expected #{function.arity} arguments but got #{arguments.size}."
      end
      function.call(self, arguments)
    end

    def visit_get_expr(expr : Get)
      object = evaluate(expr.object)
      if object.is_a? LoxInstance
        return object.get(expr.name)
      end
      raise RuntimeException.new expr.name, "Only instances have properties."
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

  class ReturnException < Exception
    getter value : LiteralType

    def initialize(@value : LiteralType)
    end
  end

  class BreakException < Exception
  end

  class NilException < Exception
  end
end
