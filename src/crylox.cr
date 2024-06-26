require "./scanner"
require "./parser"
require "./ast"
require "./ast_printer"
require "./runtime_exception"
require "./interpreter"
require "./resolver"

module Crylox
  if ARGV.size > 1
    puts "Usage: crylox [script]"
    exit 64
  elsif ARGV.size == 1
    Lox.run_file ARGV[0]
  else
    Lox.run_prompt
  end

  module Lox
    extend self
    @@had_exception = false
    @@had_runtime_exception = false
    @@interpreter = Interpreter.new

    def run_file(file_path)
      puts "Opening #{file_path}..."
      content = File.read(file_path)
      # puts "Running #{content}..."
      run content
      if @@had_exception
        exit 65
      end
      if @@had_runtime_exception
        exit 70
      end
    end

    def run_prompt
      loop do
        print "> "
        line = gets
        if line.nil?
          break
        end
        run line, true
      end
    end

    def run(source, is_repl = false)
      # puts "\n\nRunning:\n#{source}\n\n"
      scanner = Scanner.new(source)
      tokens = scanner.scan_tokens
      parser = Parser.new(tokens)
      statements = parser.parse

      # Stop if there's a parse error
      if @@had_exception
        return
      end

      resolver = Resolver.new(@@interpreter)
      resolver.resolve(statements)

      # Stop if there's a resolver error
      if @@had_exception
        return
      end

      @@interpreter.interpret(statements, is_repl)
    end

    def error(line : Int, message : String)
      report line, "", message
    end

    def error(token : Token, message : String)
      if token.type == TokenType::EOF
        report token.line, " at end", message
      else
        report token.line, " at '#{token.lexeme}'", message
      end
    end

    def runtime_exception(exception : RuntimeException)
      puts "\n\n#{exception.message}\n[line #{exception.token.line}]"
      @@had_runtime_exception = true
    end

    def report(line : Int, where : String, message : String)
      puts "[line #{line}] Error#{where}: #{message}"
      @@had_exception = true
    end
  end
end
