require "./token"

EXPR_TYPES = [
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
]

module Crylox
  macro define_visitor(base_name)
    abstract class Visitor(T)
      {% for type in EXPR_TYPES %}
        def visit_{{ type[:class].id.downcase }}_{{ base_name.id.downcase }}(expr : {{ type[:class].id }}) : T
        end
      {% end %}
    end
  end

  macro define_ast(base_name)
    abstract class {{ base_name.id }}
    end

    {% for type in EXPR_TYPES %}
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
        def accept(visitor : Visitor)
          visitor.{{ visit_class.id }}(self)
        end
      end
    {% end %}
  end

  define_visitor Expr

  define_ast Expr
end
