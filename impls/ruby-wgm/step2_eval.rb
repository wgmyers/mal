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
# Otherwise return the contents of the data
def eval_ast(ast, repl_env)
  type = ast.class.to_s
  case type
  when 'MalSymbol'
    sym = ast.print
    if repl_env.has_key?(sym)
      return repl_env[sym]
    else
      raise MalUnknownSymbolError
    end
  when 'MalList'
    retval = MalList.new
    ast.data.each do |item|
      retval.push(EVAL(item, repl_env))
    end
    return retval
  when 'MalVector'
    retval = MalVector.new
    ast.data.each do |item|
      retval.push(EVAL(item, repl_env))
    end
    return retval
  when 'MalHashMap'
    retval = MalHashMap.new
    key = true
    # We alternatve between blindly returning the untouched key and
    # calling eval on key values.
    # FIXME This is obviously nonsense behaviour and we need to revisit MalHashMap
    ast.data.each do |item|
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
  if type == 'MalList'
    if ast.data.length.zero?
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

# Print a prompt and take input
# If input is EOF then stop
# Otherwise pass input through rep and print it
def main(repl_env)
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

main(repl_env)
