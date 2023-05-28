require "./scanner"

if ARGV.size > 1
  puts "Usage: jlox [script]"
  exit 64
elsif ARGV.size == 1
  Crylox.run_file ARGV[0]
else
  Crylox.run_prompt
end

class Crylox
  @@had_error = false

  def self.run_file(file_path)
    puts "Opening #{file_path}..."
    content = File.read(file_path)
    puts "Running #{content}..."
    run content
    if @@had_error
      exit 65
    end
  end

  def self.run_prompt()
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
    scanner = Scanner.new source
    tokens = scanner.scan_tokens
    tokens.each do |token|
      puts token.to_s
    end
  end

  def self.error(line : Int, message : String)
    report line, "", message
  end

  def self.report(line : Int, where : String, message : String)
    puts "[line #{line}] Error#{where}: #{message}"
    @@had_error = true
  end
end
