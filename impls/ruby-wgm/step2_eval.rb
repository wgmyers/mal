#!/usr/bin/env ruby

# step2_eval.rb
# In which we implement a basic calculator

require_relative 'readline'
require_relative 'reader'
require_relative 'printer'
require_relative 'errors'
require_relative 'types'

# Now we are turning our input into a data structure, we can do something
# useful in the EVAL stage

# A simple environment for basic numeric functions
repl_env = {
  '+' => lambda { |x,y| x + y },
  '-' => lambda { |x,y| x - y },
  '*' => lambda { |x,y| x * y },
  '/' => lambda { |x,y| x / y }
}

# eval_ast
# Take a Mal data structure and environment
# If it's a MalSymbol, return the corresponding value fromm the environment
# or raise an error complaining about an unknown symbol
# If it's a list, make a new list containing the results of calling EVAL
# on each member of the list
# Otherwise return the data structure unchanged
def eval_ast(ast, repl_env)
  type = ast.class.to_s
  case type
  when "MalSymbol"
    sym = ast.print()
    if repl_env.has_key?(sym)
      return repl_env[sym]
    else
      raise MalUnknownSymbolError
    end
  when "MalList"
    retval = MalList.new()
    for item in ast.data
      retval.push(EVAL(item))
    end
    return retval
  end
  return ast
end

# READ
# Invokes the reader on its input
# Returns a Mal data structure or blows up on error
def READ(input)
  begin
    return read_str(input)
  rescue => e
    raise e
  end
end

# EVAL
# Finally in stage 2 we actually try and run some code.
# If we aren't given a list, we return the value of applying eval_ast to
# our input.
# If we are given a list, and it is empty, we return it.
# Otherwise, we call eval_ast on it, assume we now have a function and some
# parameters, and try and call that, returning the result.
def EVAL(ast, repl_env)
  type = ast.class.to_s
  if(type == 'MalList')
    if ast.data.length == 0
      return ast
    else
      evaller = eval_ast(ast.data)
      begin
        res = evaller.data[0].call(evaller.data.drop(1))
      rescue => e
        raise e
      end
    end
  else
    return eval_ast(ast, repl_env)
  end
end

# PRINT
# We should probably set the 'readably' flag here.
def PRINT(ast)
  return pr_str(ast)
end

# rep
# Pass input through READ, EVAL and PRINT in order and return the result
def rep(input, repl_env)
  begin
    ast = READ(input)
  rescue => e
    raise e
  end
  ast = EVAL(ast, repl_env)
  output = PRINT(ast)
  return output
end

# Print a prompt and take input
# If input is EOF then stop
# Otherwise pass input through rep and print it
def main(repl_env)
  prompt = "user> "
  loop do
    line = grabline(prompt)
    # The readline library returns nil on EOF
    if line == nil
      break
    end
    begin
      puts rep(line, repl_env)
    rescue => e
      puts "Error: " + e.message
      #puts e.backtrace
    end
  end
end

main(repl_env)
