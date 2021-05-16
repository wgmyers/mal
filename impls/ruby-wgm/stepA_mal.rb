#!/usr/bin/env ruby
# frozen_string_literal: true

# stepA_mal.rb
# In which we attempt self-hosting

require 'pp'

require_relative 'core'
require_relative 'env'
require_relative 'errors'
require_relative 'printer'
require_relative 'readline'
require_relative 'reader'
require_relative 'types'

# Some debugging flags
# Type (foo) to toggle the flag in the REPL
# We don't want to freeze this, because we intend it to be mutable.
# rubocop: disable Style/MutableConstant
DEBUG = {
  'show_ast'  => false,
  'show_env'  => false,
  'backtrace' => false
}
# rubocop: enable Style/MutableConstant

# Set startup string
STARTUP_STR = '(println (str "Mal [" *host-language* "]"))'

# READ
# Invokes the reader on its input
# Returns a Mal data structure or blows up on error
def READ(input)
  return read_str(input)
rescue => e
  raise e
end

# macroexpand
# Expand macros until we are no longer in a macro
# Calling macro_call? ensures we are always operating on a list where
# the first element is the symbol of an is_macro function.
def macroexpand(ast, env)
  while macro_call?(ast, env)
    funcsym = ast.data[0]
    func = env.get(funcsym.data)
    ast = func.call(ast.data.drop(1))
  end
  return ast
end

# macro_call?
# Take ast and env
# Return true if ast is list with symbol as first element referring to a
# function in env which has is_macro set to true
def macro_call?(ast, env)
  if ast.is_a?(MalList) && ast.data.length.positive? && ast.data[0].is_a?(MalSymbol)
    key = ast.data[0].data
    menv = env.find(key)
    return menv.data[key].is_macro if menv && menv.data[key].is_a?(MalFunction)
  end
  return false
end

# quasiquote
# A function to implement the quasiquote special form
def quasiquote(ast)
  type = ast.class.to_s
  case type
  when 'MalList'
    # If first element of list is 'unquote' symbol, return second element
    if (ast.data.length > 1) && ast.data[0].is_a?(MalSymbol) && (ast.data[0].data == 'unquote')
      retval = ast.data[1]
    else
      result = MalList.new
      ast.data.reverse.each do |elt|
        spliceresult = MalList.new
        if elt.is_a?(MalList) && (elt.data.length > 1) &&
           elt.data[0].is_a?(MalSymbol) && (elt.data[0].data == 'splice-unquote')
          # Handle splice-unquote
          spliceresult.push(MalSymbol.new('concat'))
          spliceresult.push(elt.data[1])
        else
          spliceresult.push(MalSymbol.new('cons'))
          spliceresult.push(quasiquote(elt))
        end
        spliceresult.push(result)
        result = spliceresult
      end
      retval = result
    end
  when 'MalHashMap', 'MalSymbol'
    retval = MalList.new
    retval.push(MalSymbol.new('quote'))
    retval.push(ast)
  when 'MalVector'
    retval = MalList.new
    retval.push(MalSymbol.new('vec'))
    # Now add "the result of processing ast as if it were a list not starting with unquote"
    tmplist = MalList.new
    ast.data.each { |item| tmplist.push(item) }
    # If list *does* begin with unquote, squirrel it away and add it back after processing
    if tmplist.data.length.positive? &&
       tmplist.data[0].is_a?(MalSymbol) &&
       (tmplist.data[0].data == 'unquote')
      tmplist.data[0] = MalSymbol.new('hidden-unquote') # hide the 'unquote'
      tmplist = quasiquote(tmplist)
      tmplist.data[1].data[1] = MalSymbol.new('unquote') # put it back (it's now wrapped in cons and quote)
    else
      tmplist = quasiquote(tmplist)
    end
    retval.push(tmplist)
  else
    retval = ast
  end
  return retval
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
    # Now the MalHashMap is a real hash we can do this sensibly
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
# NB - The trick we used in previous steps of returning env here turns out to
# have been a mistake, as it broke TCO. Removing it seems to have fixed most
# of the problems, though not all regression tests pass as I type this.
def EVAL(ast, env)
  # TCO YOLO
  loop do
    # If it's not a list, call eval_ast on it
    return eval_ast(ast, env) unless ast.is_a?(MalList)
    # It's a list. If it's empty, just return it.
    return ast if ast.data.length.zero?

    # Macro expansion
    ast = macroexpand(ast, env)
    unless ast.is_a?(MalList)
      next # Shorter than 'return eval_ast(ast, env)' modulo this comment.
    end

    # APPLY section
    # Switch on the first item of the list
    # FIXME This wants its own function now (or soon) surely
    case ast.data[0].data

    when 'def!', 'defmacro!'
      # Do the def! stuff
      # If defmacro! do that too
      # Only difference is we set is_macro in the MalFunction (tee hee)

      # Set is_defmacro if we are behaving as defmacro!
      is_defmacro = ast.data[0].data == 'defmacro!'
      begin
        item = EVAL(ast.data[2], env)
        if is_defmacro && item.is_a?(MalFunction)
          item = item.dup # Don't mutate existing functions, duplicate them
          item.is_macro = true
        end
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
      for param in ast.data[1].data
        if is_key
          key = param
        else
          val = EVAL(param, letenv)
          letenv = letenv.set(key, val)
        end
        is_key = !is_key
      end
      # rubocop:enable Style/For

      # TCO
      env = letenv
      ast = ast.data[2]
      next
      # ... and loop to start of EVAL

    when 'do'
      # Do the do
      # Call eval_ast on every member of the list
      # Return the value of the last one

      # TCO do
      lastel = ast.data[-1]                 # save last element of ast
      ast.data.drop(1).each { |i| EVAL(i, env) unless i == lastel }
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

      # TCO
      myfn = MalFunction.new(ast.data[2], ast.data[1], env, closure)
      return myfn

    when 'quote'
      return ast.data[1]

    when 'quasiquoteexpand'
      return quasiquote(ast.data[1])

    when 'quasiquote'
      ast = quasiquote(ast.data[1])
      next # TCO fallthrough

    when 'macroexpand'
      # I have no idea how this is supposed to work.
      return macroexpand(ast.data[1], env)

    when 'try*'
      well_formed_try = true
      begin
        # Enforce form: (try* A (catch* B C))
        # B must be a MalSymbol.
        if (ast.data.length != 3) ||
           !ast.data[2].is_a?(MalList) ||
           ast.data[2].data.length != 3 ||
           !ast.data[2].data[0].is_a?(MalSymbol) ||
           (ast.data[2].data[0].data != 'catch*') ||
           !ast.data[2].data[1].is_a?(MalSymbol)
          well_formed_try = false
          raise MalTryCatchError, 'Badly formed try*/catch* block'
        end
        try_cand = ast.data[1]
        try_err = ast.data[2].data[1]
        try_catcher = ast.data[2].data[2]
        return EVAL(try_cand, env)
      rescue => e
        # Don't try and handle malformed exceptions, just reraise
        unless well_formed_try
          # QUERY I think we should re-raise the error here.
          #       HOWEVER, to pass the test as written in step 9, we
          #       need to attempt to evaluate the next item after try*
          return EVAL(ast.data[1], env)
          # raise e
        end

        # Ok, we have B and C.
        # Check to see if we haven't been given an evaluable MalType
        err_exp = if !e.methods.include?(:malexp) || e.malexp.nil?
                    MalString.new(e.message, sanitise: false)
                  else
                    e.malexp
                  end
        err_env = Env.new(env)
        err_env.set(try_err, err_exp)
        return EVAL(try_catcher, err_env)
      end

    else
      # DEFAULT EVALLER
      # Brutal hack to allow (list + 1 2) etc
      # FIXME This really really can't be right.
      if ast.data[0].is_a?(MalSymbol) &&
         (ast.data[0].data == 'list') &&
         ast.data[1].is_a?(MalSymbol)
        f = eval_ast(ast.data.shift, env)
        squirrel = ast.data.shift
        args = eval_ast(ast, env)
        args = args.data.unshift(squirrel)
      else
        evaller = eval_ast(ast, env)
        f = evaller.data[0]
        args = evaller.data.drop(1)
      end
      begin
        # If it's a MalFunction, we can do TCO
        case f
        when MalFunction
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
  if DEBUG['show_ast']
    puts 'ast (pre EVAL):'
    pp ast
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
  MalCore::ENV.each do |key, val|
    repl_env.set(key, val)
  end
  # Support for functions defined in mal in core.rb
  MalCore::MAL.each_value do |val|
    rep(val, repl_env)
  end
  # Guide says we must define eval here. Is so we can close over repl_env?
  eval_proc = proc { |ast| EVAL(ast, repl_env) }
  repl_env.set('eval', eval_proc)
  # Add *host-language* symbol
  repl_env.set('*host-language*', MalString.new('ruby-wgm', sanitise: false))
  # Populate a dummy *ARGV* symbol
  argv = MalList.new
  repl_env.set('*ARGV*', argv)
  # If ARGV is non-empty we should treat the first item as a filename and load it
  if ARGV.length.positive?
    # Populate *ARGV* 'properly'
    # NB We need to use arg.dup as command line strings are frozen in Ruby
    # but outputting them requires a call to unmunge, which blows up on frozen strings.
    ARGV.drop(1).each { |arg| argv.push(MalString.new(arg.dup, sanitise: false)) }
    repl_env.set('*ARGV*', argv)
    # Now call rep with load-file and ARGV[0], print the result and exit
    # The [0...-4] bit is to suppress here and here only the trailing \nnil
    filename = ARGV[0]
    puts rep("(load-file \"#{filename}\")", repl_env)[0...-4]
    exit
  end
  # Add commands to twiddle our debug flags
  DEBUG.each_key do |k|
    repl_env.set(k, proc { DEBUG[k] = !DEBUG[k] })
  end
  return repl_env
end

# Print a prompt and take input
# If input is EOF then stop
# Otherwise pass input through rep and print it
def main
  repl_env = init_env
  prompt = 'user> '
  puts rep(STARTUP_STR, repl_env)[0...-4] # range suppresses trailing \nnil
  loop do
    line = grabline(prompt)
    # The readline library returns nil on EOF
    # Adding 'q' to quit because Ctrl-D at the wrong time is doing my head in
    break if line.nil? || line == 'q'

    begin
      out = rep(line, repl_env)
      puts out if out # Don't print spurious blank lines
    rescue => e
      puts "Error: #{e.message}"
      puts e.backtrace if DEBUG['backtrace']
    end
  end
end

main
