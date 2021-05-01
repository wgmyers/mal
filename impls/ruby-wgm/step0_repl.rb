#!/usr/bin/env ruby

# step0_repl.rb
# In which we implement the basic skeleton of the interpreter

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
  prompt = "user> "
  loop do
    print prompt
    line = gets
    # The following detects Ctrl-D at the beginning of a line only
    # Seems fair enough for now as it's passing tests anyway, and we're
    # about to implement some kind of readline which will hopefully handle
    # such magics for us.
    if !line
      break
    end
    puts rep(line)
  end
end

main
