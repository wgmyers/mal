#!/usr/bin/env ruby

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
  begin
    return read_str(input)
  rescue => e
    raise e
  end
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
  when "MalSymbol"
    sym = ast.print()
    # If the symbol isn't found, an error will be raised in env.rb
    begin
      return env.get(sym)
    rescue => e
      raise e
    end
  when "MalList"
    retval = MalList.new()
    for item in ast.data
      newitem, env = EVAL(item, env)
      retval.push(newitem)
    end
    return retval
  when "MalVector"
    retval = MalVector.new()
    for item in ast.data
      newitem, env = EVAL(item, env)
      retval.push(newitem)
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
        newitem, env = EVAL(item, env)
        retval.push(newitem)
      end
      key = !key
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
  if !ast.is_a?(MalList)
    return eval_ast(ast, env), env
  end
  # It's a list. If it's empty, just return it.
  if ast.data.length == 0
    return ast, env
  end
  # APPLY section
  # Switch on the first item of the list
  # FIXME This wants its own function now (or soon) surely
  case ast.data[0].data
  when "def!"
    # Do the def! stuff
    # QUERY - how does this fail? Should we raise our own BadDefError?
    begin
      item, env = EVAL(ast.data[2], env)
      return item, env.set(ast.data[1], item)
    rescue => e
      raise e
    end
  when "let*"
    # Do the let* stuff
    # Create a new environment with current env as outer
    letenv = Env.new(env)
    # Iterate over our parameters, calling set on new environment with
    # each key, value pair, first calling EVAL on the value w/ new env.
    is_key = true
    for item in ast.data[1].data
      if is_key
        key = item
      else
        val, letenv = EVAL(item, letenv)
        letenv = letenv.set(key, val)
      end
      is_key = !is_key
    end
    # Finally, call EVAL on our last parameter in the new enviroment
    # and return the result. New env is discarded, so we return the old env.
    retval, letenv = EVAL(ast.data[2], letenv)
    # Convert retval to a Mal data object if it isn't one.
    # FIXME This shouldn't be.
    if !/^Mal/.match(retval.class.to_s)
      retval = READ(retval.to_s)
    end
    return retval, env
  when "do"
    # Do the do
    # Call eval_ast on every member of the list
    # Return the value of the last one
    for item in ast.data.drop(1)
      retval, env = EVAL(item, env)
    end
    return retval, env
  when "if"
    # Handle if statements
    # (if COND X Y) returns X if COND, otherwise Y, or nil if not there.
    retval, env = EVAL(ast.data[1], env)
    if retval
      type = retval.class.to_s
    else
      type = nil
    end
    if(!type || type == "MalFalse" || type == "MalNil")
    # Falsy. Return eval of third item if there is one
      if(ast.data[3])
        return EVAL(ast.data[3], env)
      else
        return MalNil.new(), env
      end
    else
      # Truthy. Return eval of second item (or raise error)
      return EVAL(ast.data[2], env)
    end
  when "fn*"
    # Second element of the list is parameters. Third is function body.
    # So create a closure which:
    # 1 - creates a new env using our env as outer and binds /it's/
    #     parameters to the ones given using binds/exprs.
    # 2 - calls EVAL on the function body and returns it
    # We create a MalFunction to store this closure, we add a call method
    # to MalFunction, and here we return *that*.
    # Then we add code below in the DEFAULT EVALLER, to call the function
    # if it ever shows up in a list. I think. Or in eval_ast. I'm not sure.
    closure = Proc.new { |*x|
      cl_env = Env.new(env, ast.data[1].data, x)
      retval, e = EVAL(ast.data[2], cl_env)
      retval
    }
    myfn = MalFunction.new(closure)
    return myfn, env
  else
    # DEFAULT EVALLER
    evaller = eval_ast(ast, env)
    f = evaller.data[0]
    args = evaller.data.drop(1)
    begin
      #puts "args: #{args}"
      # If it's a MalFunction, we splat the args in the closure
      if(f.is_a?(MalFunction))
        res = f.call(args)
      elsif(f.is_a?(Proc))
        # Here we must splat the args with * so our lambdas can see them
        #puts "in apply with a #{f.class}"
        res = f.call(*args)
      else
        res = evaller # Here we just return our input
      end
      #puts "res: #{res}"
    rescue => e
      raise e
    end
    # Oops. We /might/ need to convert back to a Mal data type.
    case res.class.to_s
    when "TrueClass"
      return MalTrue.new(), env
    when "FalseClass"
      return MalFalse.new(), env
    when "Integer"
      return MalNumber.new(res), env
    else
      return res, env
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
# NB EVAL now returns the environment, as it might modify it.
def rep(input, repl_env)
  begin
    ast = READ(input)
  rescue => e
    raise e
  end
  ast, repl_env = EVAL(ast, repl_env)
  output = PRINT(ast)
  return output
end

# init_env
# Initialise our environment
# Use set to create the numeric functions
def init_env
  repl_env = Env.new()
  # Core environment now defined in core.rb
  MalCore::Env.each do |key, val|
    repl_env.set(key, val)
  end
  # Support for functions defined in mal in core.rb
  MalCore::Mal.each do |key, val|
    rep(val, repl_env)
  end
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
      #puts "Response:"
      puts rep(line, repl_env)
      #puts "Environment:"
      #p repl_env
    rescue => e
      puts "Error: " + e.message
      puts e.backtrace
    end
  end
end

main
