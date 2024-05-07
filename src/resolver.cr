module Crylox
  class Resolver
    @scopes = [] of Hash(String, Bool)
    @current_function = FunctionType::NONE
    @in_while = false

    def initialize(@interpreter : Interpreter)
    end

    def resolve(statements : Array(Stmt | Nil))
      statements.each do |statement|
        resolve(statement)
      end
    end

    def visit_block_stmt(stmt : Block)
      begin_scope()
      resolve(stmt.statements)
      end_scope()
      nil
    end

    def visit_class_stmt(stmt : Class)
      declare(stmt.name)
      define(stmt.name)

      stmt.methods.each do |method|
        declaration = FunctionType::METHOD
        resolve_function(method, declaration)
      end

      nil
    end

    def visit_expression_stmt(stmt : Expression)
      resolve(stmt.expression)
      nil
    end

    def visit_function_stmt(stmt : Function)
      declare(stmt.name)
      define(stmt.name)
      resolve_function(stmt, FunctionType::FUNCTION)
      nil
    end

    def visit_if_stmt(stmt : If)
      resolve(stmt.condition)
      resolve(stmt.then_branch)
      if !stmt.else_branch.nil?
        resolve(stmt.else_branch)
      end
      nil
    end

    def visit_print_stmt(stmt : Print)
      resolve(stmt.expression)
      nil
    end

    def visit_return_stmt(stmt : Return)
      if @current_function == FunctionType::NONE
        Lox.error(stmt.keyword, "Can't return from top-level code.")
      end
      if !stmt.value.nil?
        resolve(stmt.value)
      end
      nil
    end

    def visit_var_stmt(stmt : Var)
      declare(stmt.name)
      if !stmt.initializer.nil?
        resolve(stmt.initializer)
      end
      define(stmt.name)
      nil
    end

    def visit_while_stmt(stmt : While)
      resolve(stmt.condition)
      @in_while = true
      resolve(stmt.body)
      @in_while = false
      nil
    end

    def visit_break_stmt(stmt : Break)
      if !@in_while
        Lox.error(stmt.keyword, "Can't break outside of a loop.")
      end
    end

    def visit_assign_expr(expr : Assign)
      resolve(expr.value)
      resolve_local(expr, expr.name)
      nil
    end

    def visit_binary_expr(expr : Binary)
      resolve(expr.left)
      resolve(expr.right)
      nil
    end

    def visit_lambda_expr(expr : Lambda)
      resolve_function(expr, FunctionType::FUNCTION)
      nil
    end

    def visit_call_expr(expr : Call)
      resolve(expr.callee)
      expr.arguments.each do |argument|
        resolve(argument)
      end
      nil
    end

    def visit_get_expr(expr : Get)
      resolve(expr.object)
      nil
    end

    def visit_grouping_expr(expr : Grouping)
      resolve(expr.expression)
      nil
    end

    def visit_literal_expr(expr : Literal)
      nil
    end

    def visit_logical_expr(expr : Logical)
      resolve(expr.left)
      resolve(expr.right)
      nil
    end

    def visit_set_expr(expr : Set)
      resolve(expr.value)
      resolve(expr.object)
      nil
    end

    def visit_unary_expr(expr : Unary)
      resolve(expr.right)
      nil
    end

    def visit_variable_expr(expr : Variable)
      if !@scopes.empty? && @scopes[-1][expr.name.lexeme]? == false
        Lox.error(expr.name, "Can't read local variable in its own initializer.")
      end

      resolve_local(expr, expr.name)
      nil
    end

    def resolve(stmt : Stmt | Nil)
      if !stmt.nil?
        stmt.not_nil!.accept(self)
      end
    end

    def resolve(expr : Expr)
      expr.accept(self)
    end

    def resolve_function(function : Function | Lambda, type : FunctionType)
      enclosing_function = @current_function
      @current_function = type
      begin_scope()
      function.params.each do |param|
        declare(param)
        define(param)
      end
      resolve(function.body)
      end_scope()
      @current_function = enclosing_function
    end

    def begin_scope
      @scopes << Hash(String, Bool).new
    end

    def end_scope
      @scopes.pop
    end

    def declare(name : Token)
      if @scopes.empty?
        return
      end
      scope = @scopes[-1]
      if scope.has_key?(name.lexeme)
        Lox.error(name, "Already a variable with this name in this scope.")
      end
      scope[name.lexeme] = false
    end

    def define(name : Token)
      if @scopes.empty?
        return
      end
      @scopes[-1][name.lexeme] = true
    end

    def resolve_local(expr : Expr, name : Token)
      @scopes.reverse_each.with_index do |scope, i|
        if scope.has_key?(name.lexeme)
          @interpreter.resolve(expr, i)
          return
        end
      end
    end
  end

  enum FunctionType
    NONE
    FUNCTION
    METHOD
  end
end
