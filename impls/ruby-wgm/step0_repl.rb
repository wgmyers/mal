#!/usr/bin/env ruby

# step0_repl.rb
# In which we implement the basic skeleton of the interpreter

require_relative 'readline'

# In this step, READ, EVAL and PRINT just return their arguments
def READ(arg)
  return arg
end
def EVAL(arg)
  return arg
end
def PRINT(arg)
  return arg
end

# Here, rep just passes arg to READ, EVAL and PRINT in order and returns the result
def rep(arg)
  arg = READ(arg)
  arg = EVAL(arg)
  arg = PRINT(arg)
  return arg
end

# Print a prompt and take input
# If input is EOF then stop
# Otherwise pass input through rep and print it
def main()
  prompt = 'user> '
  loop do
    line = grabline(prompt)
    # The readline library returns nil on EOF
    break if line == nil

    puts rep(line)
  end
end

main
