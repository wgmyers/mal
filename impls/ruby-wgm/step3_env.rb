#!/usr/bin/env ruby

# step3_env.rb
# In which we implement a Lisp environment

require_relative 'env'
require_relative 'errors'
require_relative 'printer'
require_relative 'readline'
require_relative 'reader'
require_relative 'types'

# eval_ast
# Take a Mal data structure and environment
# If it's a MalSymbol, return the corresponding value fromm the environment
# or raise an error complaining about an unknown symbol
# If it's a list, make a new list containing the results of calling EVAL
# on each member of the list
# Otherwise return the contents of the data
def eval_ast(ast, repl_env)
  type = ast.class.to_s
  case type
  when "MalSymbol"
    sym = ast.print()
    # If the symbol isn't found, an error will be raised in env.rb
    begin
      return repl_env.get(sym)
    rescue => e
      raise e
    end
  when "MalList"
    retval = MalList.new()
    for item in ast.data
      retval.push(EVAL(item, repl_env))
    end
    return retval
  when "MalVector"
    retval = MalVector.new()
    for item in ast.data
      retval.push(EVAL(item, repl_env))
    end
    return retval
  when "MalHashMap"
    retval = MalHashMap.new()
    key = true
    # We alternatve between blindly returning the untouched key and
    # calling eval on key values.
    # FIXME This is obviously nonsense behaviour and we need to revisit MalHashMap
    for item in ast.data
      if key
        retval.push(item)
      else
        retval.push(EVAL(item, repl_env))
      end
      key = !key
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
      evaller = eval_ast(ast, repl_env)
      begin
        # We need to convert our MalNumbers to actual numbers somehow. Here?
        args = evaller.data.drop(1).map{ |x| x.data }
        # We still need to splat the args with * so the lambda can see them
        res = evaller.data[0].call(*args)
      rescue => e
        raise e
      end
      # Oops. We need to convert back to a Mal data type.
      return MalNumber.new(res)
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

# init_env
# Initialise our environment
# Use set to create the numeric functions
def init_env
  repl_env = Env.new()
  # A simple environment for basic numeric functions
  numeric_env = {
    '+' => lambda { |x,y| x + y },
    '-' => lambda { |x,y| x - y },
    '*' => lambda { |x,y| x * y },
    '/' => lambda { |x,y| x / y }
  }
  numeric_env.each do |key, val|
    repl_env.set(key, val)
  end
  puts "init_env checking in:"
  p repl_env
  return repl_env
end

# Print a prompt and take input
# If input is EOF then stop
# Otherwise pass input through rep and print it
def main()
  repl_env = init_env()
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
      puts e.backtrace
    end
  end
end

main
