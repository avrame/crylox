require "./token"

module Crylox
  macro define_visitor(base_name, types)
    module {{base_name}}Visitor(T)
      {% for type in types %}
        def visit_{{ type[:class].id.downcase }}_{{ base_name.id.downcase }}(expr : {{ type[:class].id }}) : T
        end
      {% end %}
    end
  end

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
  ]

  define_visitor Expr, {{EXPR_TYPES}}
  define_ast Expr, {{EXPR_TYPES}}

  STMT_TYPES = [
    {
      class:  Block,
      fields: [
        {type: Array(Stmt), name: statements},
      ],
    },
    {
      class:  Expression,
      fields: [
        {type: Expr, name: expression},
      ],
    },
    {
      class:  Print,
      fields: [
        {type: Expr, name: expression},
      ],
    },
    {
      class:  Var,
      fields: [
        {type: Token, name: name},
        {type: Expr | Nil, name: initializer},
      ],
    },
  ]

  define_visitor Stmt, {{STMT_TYPES}}
  define_ast Stmt, {{STMT_TYPES}}
end
