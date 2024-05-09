require "./token"

module Crylox
  macro define_ast(base_name, types)
    abstract class {{ base_name.id }}
    end

    {% for type in types %}
      {% fields = type[:fields] %}
      class {{ type[:class].id }} < {{ base_name.id }}
        {% for field in fields %}
          property :{{ field[:name].id }}
        {% end %}

        {% for field in fields %}
          @{{ field[:name].id }} : {{ field[:type].id }}
        {% end %}

        {% args_arr = [] of StringLiteral %}
        {% for field in fields %}
          {% args_arr << "#{field[:name].id} : #{field[:type].id}" %}
        {% end %}
        {% args_str = args_arr.join(", ") %}

        def initialize({{ args_str.id }})
          {% for field in fields %}
            @{{ field[:name].id }} = {{ field[:name].id }}
          {% end %}
        end

        {% visit_class = "visit_#{type[:class].id.downcase}_#{base_name.id.downcase}" %}
        def accept(visitor)
          visitor.{{ visit_class.id }}(self)
        end
      end
    {% end %}
  end

  EXPR_TYPES = [
    {
      class:  Assign,
      fields: [
        {type: Token, name: name},
        {type: Expr, name: value},
      ],
    },
    {
      class:  Binary,
      fields: [
        {type: Expr, name: left},
        {type: Token, name: operator},
        {type: Expr, name: right},
      ],
    },
    {
      class:  Call,
      fields: [
        {type: Expr, name: callee},
        {type: Token, name: paren},
        {type: Array(Expr), name: arguments},
      ],
    },
    {
      class:  Get,
      fields: [
        {type: Expr, name: object},
        {type: Token, name: name},
      ],
    },
    {
      class:  Grouping,
      fields: [
        {type: Expr, name: expression},
      ],
    },
    {
      class:  Literal,
      fields: [
        {type: LiteralType, name: value},
      ],
    },
    {
      class:  Logical,
      fields: [
        {type: Expr, name: left},
        {type: Token, name: operator},
        {type: Expr, name: right},
      ],
    },
    {
      class:  Set,
      fields: [
        {type: Expr, name: object},
        {type: Token, name: name},
        {type: Expr, name: value},
      ],
    },
    {
      class: This,
      fields: [{type: Token, name: keyword}],
    },
    {
      class:  Unary,
      fields: [
        {type: Token, name: operator},
        {type: Expr, name: right},
      ],
    },
    {
      class:  Variable,
      fields: [{type: Token, name: name}],
    },
    {
      class:  Lambda,
      fields: [
        {type: Array(Token), name: params},
        {type: Array(Stmt), name: body},
      ],
    },
  ]

  define_ast Expr, {{EXPR_TYPES}}

  STMT_TYPES = [
    {
      class:  Block,
      fields: [
        {type: Array(Stmt), name: statements},
      ],
    },
    {
      class:  Class,
      fields: [
        {type: Token, name: name},
        {type: Array(Function), name: methods},
      ],
    },
    {
      class:  Expression,
      fields: [
        {type: Expr, name: expression},
      ],
    },
    {
      class:  Function,
      fields: [
        {type: Token, name: name},
        {type: Array(Token), name: params},
        {type: Array(Stmt), name: body},
      ],
    },
    {
      class:  If,
      fields: [
        {type: Expr, name: condition},
        {type: Stmt, name: then_branch},
        {type: Stmt | Nil, name: else_branch},
      ],
    },
    {
      class:  Print,
      fields: [
        {type: Expr, name: expression},
      ],
    },
    {
      class:  Return,
      fields: [
        {type: Token, name: keyword},
        {type: Expr | Nil, name: value},
      ],
    },
    {
      class:  Var,
      fields: [
        {type: Token, name: name},
        {type: Expr | Nil, name: initializer},
      ],
    },
    {
      class:  While,
      fields: [
        {type: Expr, name: condition},
        {type: Stmt, name: body},
      ],
    },
    {
      class:  Break,
      fields: [
        {type: Token, name: keyword},
      ],
    },
  ]

  define_ast Stmt, {{STMT_TYPES}}
end
