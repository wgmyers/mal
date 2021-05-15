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
def eval_ast(ast, env)
  type = ast.class.to_s
  case type
  when 'MalSymbol'
    sym = ast.print
    # If the symbol isn't found, an error will be raised in env.rb
    begin
      return env.get(sym)
    rescue => e
      raise e
    end
  when 'MalList'
    retval = MalList.new
    ast.data.each do |item|
      newitem = EVAL(item, env)
      retval.push(newitem)
    end
    return retval
  when 'MalVector'
    retval = MalVector.new
    ast.data.each do |item|
      newitem = EVAL(item, env)
      retval.push(newitem)
    end
    return retval
  when 'MalHashMap'
    retval = MalHashMap.new
    ast.data.each_key do |key|
      retval.set(key, EVAL(ast.data[key], env))
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
# In stage 3 we implement core language features def! and let* in the APPLY bit
# If we aren't given a list, we return the value of applying eval_ast to
# our input.
# If we are given a list, and it is empty, we return it.
# Otherwise, we are in APPLY.
# Here we check to see if the first item of the list is def! or let* and if so,
# we do the needful.
# Otherwise we go ahead as in Step 2:
# Call eval_ast on the list, assume we now have a function and some
# parameters, and try and call that, returning the result.
def EVAL(ast, env)
  return eval_ast(ast, env) unless ast.instance_of?(MalList)

  return ast if ast.data.length.zero?

  # APPLY section
  # Switch on the first item of the list
  # FIXME This wants its own function now (or soon) surely
  case ast.data[0].data
  when 'def!'
    # Do the def! stuff
    # QUERY - how does this fail? Should we raise our own BadDefError?
    begin
      item = EVAL(ast.data[2], env)
      env = env.set(ast.data[1], item)
      return item
    rescue => e
      raise e
    end
  when 'let*'
    # Do the let* stuff
    # Create a new environment with current env as outer
    letenv = Env.new(env)
    # Iterate over our parameters, calling set on new environment with
    # each key, value pair, first calling EVAL on the value w/ new env.
    is_key = true
    # NB Using 'each' here fails. I have no idea why.
    # rubocop:disable Style/For
    for item in ast.data[1].data
      if is_key
        key = item
      else
        val = EVAL(item, letenv)
        letenv = letenv.set(key, val)
      end
      is_key = !is_key
    end
    # rubocop:enable Style/For
    # Finally, call EVAL on our last parameter in the new enviroment
    # and return the result.
    retval = EVAL(ast.data[2], letenv)
    # Convert retval to a Mal data object if it isn't one.
    # FIXME This shouldn't be.
    retval = READ(retval.to_s) unless /^Mal/.match(retval.class.to_s)
    return retval
  else
    evaller = eval_ast(ast, env)
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
  repl_env = Env.new
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
  return repl_env
end

# Print a prompt and take input
# If input is EOF then stop
# Otherwise pass input through rep and print it
def main
  repl_env = init_env
  prompt = 'user> '
  loop do
    line = grabline(prompt)
    # The readline library returns nil on EOF
    break if line == nil

    begin
      puts rep(line, repl_env)
    rescue => e
      puts 'Error: ' + e.message
      puts e.backtrace
    end
  end
end

main
