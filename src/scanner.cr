require "./token_type"
require "./token"
require "./crylox"

class Scanner
  @@keywords = {
    "and" => TokenType::AND,
    "class" => TokenType::CLASS,
    "else" => TokenType::ELSE,
    "false" => TokenType::FALSE,
    "for" => TokenType::FOR,
    "fun" => TokenType::FUN,
    "if" => TokenType::IF,
    "nil" => TokenType::NIL,
    "or" => TokenType::OR,
    "print" => TokenType::PRINT,
    "return" => TokenType::RETURN,
    "super" => TokenType::SUPER,
    "this" => TokenType::THIS,
    "true" => TokenType::TRUE,
    "var" => TokenType::VAR,
    "while" => TokenType::WHILE,
  }
  @tokens = [] of Token
  @start : Int64 = 0
  @current : Int64 = 0
  @line : Int64 = 1

  def initialize(@source : String)
  end

  def scan_tokens()
    while !is_at_end?
      @start = @current
      scan_token
    end

    @tokens << Token.new TokenType::EOF, "", nil, @line
    @tokens
  end

  private def is_at_end?
    @current >= @source.size
  end

  private def scan_token()
    c : Char = advance()
    case c
    when '(' then add_token TokenType::LEFT_PAREN
    when ')' then add_token TokenType::RIGHT_PAREN
    when '{' then add_token TokenType::LEFT_BRACE
    when '}' then add_token TokenType::RIGHT_BRACE
    when ',' then add_token TokenType::COMMA
    when '.' then add_token TokenType::DOT
    when '-' then add_token TokenType::MINUS
    when '+' then add_token TokenType::PLUS
    when ';' then add_token TokenType::SEMICOLON
    when '*' then add_token TokenType::STAR
    when '!' then add_token(match('=') ? TokenType::BANG_EQUAL : TokenType::BANG)
    when '=' then add_token(match('=') ? TokenType::EQUAL_EQUAL : TokenType::EQUAL)
    when '<' then add_token(match('=') ? TokenType::LESS_EQUAL : TokenType::LESS)
    when '>' then add_token(match('=') ? TokenType::GREATER_EQUAL : TokenType::GREATER)
    when '/' then
      if match '/'
        # It's a single-line comment
        while peek != '\n' && !is_at_end?
          advance
        end
      elsif match '*'
        # It's a block comment
        depth = 1
        until depth == 0 || is_at_end?
          char = advance
          if char == '\n'
            @line += 1
          elsif char == '*' && peek == '/'
            depth -= 1
          elsif char == '/' && peek == '*'
            depth += 1
          end
        end
        if !is_at_end?
          advance
        end
      else
        add_token TokenType::SLASH
      end
    when ' ', '\r', '\t'
      # noop
    when '\n'
      @line += 1
    when '"' then string
    when .number? then number
    when .letter? then identifier
    else Crylox.error @line, "Unexpected character."
    end
  end

  private def advance() : Char
    char = @source[@current]
    @current += 1
    char
  end

  private def add_token(type : TokenType)
    add_token type, nil
  end

  private def add_token(type : TokenType, literal : String | Float64 | Nil)
    text = @source[@start...@current]
    @tokens << Token.new type, text, literal, @line
  end

  private def match(expected : Char) : Bool
    if is_at_end?
      return false
    end

    if @source[@current] != expected
      return false
    end

    @current += 1
    true
  end

  private def peek()
    if is_at_end?
      return '\0'
    end
    @source[@current]
  end

  private def peek_next()
    if @current + 1 >= @source.size
      return '\0'
    end
    @source[@current + 1]
  end

  private def string()
    while peek != '"' && !is_at_end?
      if peek == '\n'
        @line += 1
      end
      advance
    end

    if is_at_end?
      Crylox.error @line, "Unterminated string."
      return
    end

    # The closing ".
    advance

    # Trim the surrounding quotes.
    value = @source[@start + 1...@current - 1]
    add_token TokenType::STRING, value
  end

  private def number()
    while peek.number?
      advance
    end

    if peek == '.' && peek_next.number?
      # consume the "."
      advance
      while peek.number?
        advance
      end
    end

    add_token TokenType::NUMBER, @source[@start...@current].to_f64
  end

  private def identifier()
    while peek.alphanumeric? || peek == '_'
      advance
    end
    text = @source[@start...@current]
    type = @@keywords[text]?
    if type.nil?
      type = TokenType::IDENTIFIER
    end

    add_token type
  end
end
