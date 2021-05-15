#!/usr/bin/env ruby
# frozen_string_literal: true

# step1_read_print.rb
# In which we tokenise our input and untokenise it again for printing

require_relative 'readline'
require_relative 'reader'
require_relative 'printer'

# In earlier steps READ, EVAL and PRINT just return their arguments
# But now we want to catch errors from read_str and pass them back to
# our main loop. Later, presumably, we catch errors from EVAL also, and
# for completeness, from PRINT.
def READ(arg)
  begin
    return read_str(arg)
  rescue => e
    raise e
  end
end
def EVAL(arg)
  return arg
end
def PRINT(arg)
  return pr_str(arg)
end

# Here, rep just passes arg to READ, EVAL and PRINT in order and returns the result
def rep(arg)
  begin
    arg = READ(arg)
  rescue => e
    raise e
  end
  arg = EVAL(arg)
  arg = PRINT(arg)
  return arg
end

# Print a prompt and take input
# If input is EOF then stop
# Otherwise pass input through rep and print it
def main
  prompt = 'user> '
  loop do
    line = grabline(prompt)
    # The readline library returns nil on EOF
    break if line.nil?

    begin
      puts rep(line)
    rescue => e
      puts "Error: #{e.message}"
    end
  end
end

main
