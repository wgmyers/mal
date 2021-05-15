#!/usr/bin/env ruby
# frozen_string_literal: true

# step4_if_fn_do.rb
# In which we implement some core language features.

require_relative 'core'
require_relative 'env'
require_relative 'errors'
require_relative 'printer'
require_relative 'readline'
require_relative 'reader'
require_relative 'types'

# READ
# Invokes the reader on its input
# Returns a Mal data structure or blows up on error
def READ(input)
  return read_str(input)
rescue => e
  raise e
end

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

# EVAL
# In stage 4 we implement more core language in the APPLY bit
# If we aren't given a list, we return the value of applying eval_ast to
# our input.
# If we are given a list, and it is empty, we return it.
# Otherwise, we are in APPLY.
# Here we check to see if the first item of the list is a special keyword and
# if so, we do the needful.
# Otherwise we go ahead as in Step 2:
# Call eval_ast on the list, assume we now have a function and some
# parameters, and try and call that, returning the result.
# NB - We now return the environment along with our result, so that the env
# object persists. Not quite what the guide asks for but this way we avoid
# having to use a global, at the cost of some readability.
def EVAL(ast, env)
  # If it's not a list, call eval_ast on it
  return eval_ast(ast, env) unless ast.instance_of?(MalList)
  # It's a list. If it's empty, just return it.
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
    # and return the result. New env is discarded, so we return the old env.
    retval = EVAL(ast.data[2], letenv)
    # Convert retval to a Mal data object if it isn't one.
    # FIXME This shouldn't be.
    retval = READ(retval.to_s) unless /^Mal/.match(retval.class.to_s)
    return retval
  when 'do'
    # Do the do
    # Call eval_ast on every member of the list
    # Return the value of the last one
    ast.data.drop(1).each do |el|
      retval = EVAL(el, env)
    end
    return retval
  when 'if'
    # Handle if statements
    # (if COND X Y) returns X if COND, otherwise Y, or nil if not there.
    retval = EVAL(ast.data[1], env)
    type = (retval.class.to_s if retval)
    # Truthy. Return eval of second item
    return EVAL(ast.data[2], env) unless !type || type == 'MalFalse' || type == 'MalNil'
    # Falsy. Return eval of third item if there is one
    return MalNil.new unless ast.data[3]

    return EVAL(ast.data[3], env)
  when 'fn*'
    # Second element of the list is parameters. Third is function body.
    # So create a closure which:
    # 1 - creates a new env using our env as outer and binds /it's/
    #     parameters to the ones given using binds/exprs.
    # 2 - calls EVAL on the function body and returns it
    # We create a MalFunction to store this closure, we add a call method
    # to MalFunction, and here we return *that*.
    # Then we add code below in the DEFAULT EVALLER, to call the function
    # if it ever shows up in a list. I think. Or in eval_ast. I'm not sure.
    closure = proc { |*x|
      cl_env = Env.new(env, ast.data[1].data, x)
      retval, e = EVAL(ast.data[2], cl_env)
      retval
    }
    # NB - At Step 4 we only use the closure. Later stages add other params to
    # the MalFunction initialiser, hence all the nils here, as we only have one
    # types.rb and I don't want to keep the old MalFunction around.
    myfn = MalFunction.new(nil, nil, nil, closure)
    return myfn
  else
    # DEFAULT EVALLER
    evaller = eval_ast(ast, env)
    f = evaller.data[0]
    args = evaller.data.drop(1)
    begin
      # If it's a MalFunction, we splat the args in the closure
      res = case f
            when MalFunction
              f.call(args)
            when Proc
              # Here we must splat the args with * so our lambdas can see them
              f.call(*args)
            else
              evaller # Here we just return our input
            end
    rescue => e
      raise e
    end
    # Oops. We /might/ need to convert back to a Mal data type.
    case res.class.to_s
    when 'TrueClass'
      return MalTrue.new
    when 'FalseClass'
      return MalFalse.new
    when 'Integer'
      return MalNumber.new(res)
    else
      return res
    end
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
  # Core environment now defined in core.rb
  MalCore::Env.each do |key, val|
    repl_env.set(key, val)
  end
  # Support for functions defined in mal in core.rb
  MalCore::Mal.each do |key, val|
    next if key == 'cond' # NB Needed as we don't implement defmacro! until step 8

    rep(val, repl_env)
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
    break if line.nil?

    begin
      puts rep(line, repl_env)
    rescue => e
      puts "Error: #{e.message}"
      puts e.backtrace
    end
  end
end

main
