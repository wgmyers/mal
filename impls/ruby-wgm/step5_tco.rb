#!/usr/bin/env ruby
# frozen_string_literal: true

# step5_tco.rb
# In which we implement tail call optimisation

require 'pp'

require_relative 'core'
require_relative 'env'
require_relative 'errors'
require_relative 'printer'
require_relative 'readline'
require_relative 'reader'
require_relative 'types'

# Some debugging flags
DEBUG = {
  'show_env'  => false,
  'backtrace' => false
}.freeze

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
# Stage 5 refactors EVAL to handle TCO.
# We put an infinite loop around the whole thing.
# Whenever possible, by which we mean user-defined functions, let*, do and if,
# we don't return anything but instead prepare the variables ast and env for
# another run round the loop. This saves a stack frame and allows for deep
# recursion. I think, and is compulsory in Scheme and related Lisps. I don't
# really understand it yet, but that's what you get for trying to learn Lisp
# by implementing it.
def EVAL(ast, env)
  # TCO YOLO
  loop do
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
      # NB - No TCO here. We return.
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

      # Pre TCO
      # # Finally, call EVAL on our last parameter in the new enviroment
      # # and return the result. New env is discarded, so we return the old env.
      # # retval, letenv = EVAL(ast.data[2], letenv)
      # Convert retval to a Mal data object if it isn't one.
      # # FIXME: This shouldn't be.
      # if !/^Mal/.match(retval.class.to_s)
      #   retval = READ(retval.to_s)
      # end
      # return retval

      # TCO way
      env = letenv
      ast = ast.data[2]
      next
      # ... and loop to start of EVAL

    when 'do'
      # Do the do
      # Call eval_ast on every member of the list
      # Return the value of the last one

      # Pre TCO do
      # for item in ast.data.drop(1)
      #   retval = EVAL(item, env)
      # end
      # return retval

      # TCO do
      lastel = ast.data.pop                 # save last element of ast
      ast.data.drop(1).each { |i| EVAL(i, env) }
      ast = lastel                          # set ast to saved last element
      next
      # ... and loop to start of EVAL

    when 'if'
      # Handle if statements
      # (if COND X Y) returns X if COND, otherwise Y, or nil if not there.
      retval = EVAL(ast.data[1], env)
      type = (retval.class.to_s if retval)
      if !type || type == 'MalFalse' || type == 'MalNil'
        # Falsy. Return eval of third item if there is one
        return MalNil.new unless ast.data[3]

        ast = ast.data[3]
      else
        # Truthy. Return eval of second item (or raise error)
        # Pre TCO - return EVAL(ast.data[2], env)
        ast = ast.data[2]
      end
      next
      # ... and loop to start of EVAL

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
        retval = EVAL(ast.data[2], cl_env)
      }

      # Pre TCO way
      # myfn = MalFunction.new(closure)
      # return myfn

      # TCO way
      # NB - We also modify MalFunction over in types.rb to reflect the new
      #      function design:  MalFunction.new(ast, params, env, closure)
      myfn = MalFunction.new(ast.data[2], ast.data[1], env, closure)
      return myfn
    else
      # DEFAULT EVALLER
      evaller = eval_ast(ast, env)
      f = evaller.data[0]
      args = evaller.data.drop(1)
      begin
        # If it's a MalFunction, we can do TCO
        case f
        when MalFunction
          # pre TCO
          # res = f.call(args)
          # TCO
          ast = f.ast
          env = Env.new(f.env, f.params.data, args)
          next
          # ... and loop to start for TCO
        when Proc
          # No TCO here - we can return a result
          # Here we must splat the args with * so our lambdas can see them
          res = f.call(*args)
        else
          res = evaller # Here we just return our input
        end
      rescue => e
        raise e
      end
      # Oops. We /might/ need to convert back to a Mal data type.
      # FIXME I'm sure this shouldn't ever be the case.
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
  ast = EVAL(ast, repl_env)
  if DEBUG['show_env']
    puts 'Env:'
    pp repl_env
  end
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
    # Adding 'q' to quit because Ctrl-D at the wrong time is doing my head in
    break if line.nil? || line == 'q'

    begin
      puts rep(line, repl_env)
    rescue => e
      puts "Error: #{e.message}"
      puts e.backtrace if DEBUG['backtrace']
    end
  end
end

main
