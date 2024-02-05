require "./token"

module Crylox
  macro define_ast(base_name, types)
    abstract class {{ base_name.id }}
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

        {% visit_class = "visit#{type[:class].id}#{base_name.id}" %}
        def accept(visitor)
          visitor.{{ visit_class.id }}(self)
        end
      end
    {% end %}
    end
  end

  define_ast Expr, [
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
end
