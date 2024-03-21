require "./scanner"
require "./parser"
require "./ast"
require "./ast_printer"
require "./runtime_exception"
require "./interpreter"

module Crylox
  if ARGV.size > 1
    puts "Usage: crylox [script]"
    exit 64
  elsif ARGV.size == 1
    Lox.run_file ARGV[0]
  else
    Lox.run_prompt
  end

  class Lox
    @@had_exception = false
    @@had_runtime_exception = false
    @@interpreter = Interpreter.new

    def self.run_file(file_path)
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

    def self.run_prompt
      loop do
        print "> "
        line = gets
        if line.nil?
          break
        end
        run line
      end
    end

    def self.run(source)
      puts "Running #{source}"
      scanner = Scanner.new(source)
      tokens = scanner.scan_tokens
      parser = Parser.new(tokens)
      expression = parser.parse

      if @@had_exception
        return
      end

      unless expression.nil?
        ast_printer = AstPrinter.new
        puts ast_printer.print(expression)
        @@interpreter.interpret(expression)
      end
    end

    def self.error(line : Int, message : String)
      report line, "", message
    end

    def self.error(token : Token, message : String)
      if token.type == TokenType::EOF
        report token.line, " at end", message
      else
        report token.line, " at '#{token.lexeme}'", message
      end
    end

    def self.runtime_exception(exception : RuntimeException)
      puts "#{exception.message}\n[line #{exception.token.line}]"
      @@had_runtime_exception = true
    end

    def self.report(line : Int, where : String, message : String)
      puts "[line #{line}] Error#{where}: #{message}"
      @@had_exception = true
    end
  end
end
