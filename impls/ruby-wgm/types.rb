#!/usr/bin/env ruby

# types.rb

# Classes to define the different types we support in Mal

require_relative "errors"

# MalType is the base class for our class types
class MalType

  attr_reader :type, :data

  def initialize()
    @type = "MalBaseType"
    @data = nil
  end

  def print(readably = true)
    return @data
  end

end

class MalAtom < MalType

  attr_reader :type, :data

  # data must be a Mal object
  def initialize(data)
    @type = "MalAtom"
    @data = data
  end

  # Produce output indicated by the test case
  def print(readably = true)
    return "(atom #{@data.print()})"
  end

  # deref
  # Allows us to implement deref so it only works on MalAtoms
  # NB Don't give any other MalObject a deref method.
  def deref()
    return @data
  end

  # reset expects data to be a Mal object
  def reset(data)
    @data = data
  end

  # arr contains a Mal function and zero or more arguments
  # We take the first element of the array to get the function
  # We prepend self to the remaining array, possibly empty
  # Now we can call the function.
  # We need to check if it's a MalFunction or a core lambda
  # to get the calling semantics right.
  # FIXME - Error checking here? What if we aren't given a function at all?
  def swap(arr)
    fn = arr.shift()
    args = arr.unshift(@data)
    if (fn.is_a?(MalFunction))
      @data = fn.call(args)
    else
      @data = fn.call(*args)
    end
  end

end

# MalFunction
# Tee hee
class MalFunction < MalType

  attr_reader :ast, :params, :env, :closure, :data
  attr_accessor :is_macro

  # Here we expect data to be a Proc
  # FIXME We should complain if it isn't
  def initialize(ast, params, env, closure)
    @type = "MalFunction"
    @ast = ast
    @params = params
    @env = env
    @closure = closure
    @is_macro = false
    @data = self # Will this work or blow up?
  end

  # #<function> is what the guide says to do
  # It would be nice to have a way of reading the function back too somehow.
  def print(readably = true)
    return "#<function>"
  end

  # This way we don't have to access @closure directly
  def call(args)
    return @closure.call(*args)
  end

end

# MalString
# Here be dragons
class MalString < MalType

  # By default we sanitise our string inputs
  # But when we print from core.rb, we don't want to, so from there
  # we call with the sanitise flag set to false.
  def initialize(data, sanitise=true)
    @type = "MalString"
    @data = data
    if sanitise
      @data = _sanitise(@data)
    end
  end

  def print(readably = true)
    if readably
      return _unmunge(@data)
    end
    return @data
  end

  # _sanitise
  # String sanitising:
  # First check we have a trailing quote and raise error if not
  # Next check to see if all we have is a single quote - error if so
  # Then strip leading and trailing quotes
  # Then check for an odd number of trailing backslashes and raise error if so
  # Then we can safely munge our remaining string.
  def _sanitise(str)
    _trailing_quote_check(str)
    _single_quote_check(str)
    str = _strip_quotes(str)
    _unescaped_quote_check(str)
    _trailing_backslash_check(str)
    str = _munge(str)
    return str
  end

  # _trailing_backslash_check
  # If we have one or more trailing backslashes, count them
  # If the number is even, we're ok
  # If the number is odd, the last one will escape the quote, and we have an error
  def _trailing_backslash_check(str)
    if(m = /(\\+)$/.match(str))
      #puts "_trailing_backslash_check found #{m[0].length} trailing backslashes"
      if m[0].length.odd?
        raise MalMismatchQuotesError
      end
    end
  end

  # _single_quote_check
  # Raise an error if all we have is a lone quote
  def _single_quote_check(str)
    if str == "\""
      raise MalMismatchQuotesError
    end
  end

  # _trailing_quote_check
  # Check there /is/ a trailing quote at the end of the string
  # Raise an error if not
  def _trailing_quote_check(str)
    if !(/\"$/.match(str))
      #puts "MalString _trailing_quote_check: rejecting #{str}"
      raise MalMismatchQuotesError
    end
  end

  # _unescaped_quote_check
  # Run this after we have stripped our leading and trailing quotes.
  def _unescaped_quote_check(str)
    if (/[^\\]\"/.match(str))
      raise MalMisMatchQuotesError
    end
  end

  # _strip_quotes
  # Remove quotes from beginning and end of string
  # We are only called with strings that begin with quotes
  # We call this after checking there is a trailing quote
  def _strip_quotes(str)
    str.sub!(/^\"/, "")
    str.sub!(/\"$/, "")
    return str;
  end

  # _munge and _unmunge handle our backslash escaping 'sensibly'
  # \" => "
  # \\ => \
  # \n => actual newline
  def _munge(str)
    str.gsub!(/\\\\/, "{esc-bs}")
    str.gsub!(/\\\"/, "\"")
    str.gsub!(/\\n/, "\n")
    str.gsub!("{esc-bs}", "\\")
    return str
  end

  def _unmunge(str)
    str.gsub!(/(\\)/, '\\1\\1') # MUST do this first
    str.gsub!(/\n/, "\\n")
    str.gsub!(/\"/, "\\\"")
    return "\"" + str + "\""
  end

end

# NB - consider having MalBoolean for both true and false?
class MalTrue < MalType

  def initialize()
    @type = "MalTrue"
    @data = true
  end

  def print(readably = true)
    return "true"
  end

end
class MalFalse < MalType

  def initialize()
    @type = "MalFalse"
    @data = false
  end

  def print(readably = true)
    return "false"
  end

end

class MalNil < MalType

  def initialise()
    @type = "MalNil"
    @data = nil
  end

  def print(readably = true)
    return "nil"
  end

end

class MalList < MalType

  def initialize()
    @type = "MalList"
    @data = []
  end

  def push(item)
    @data.push(item)
  end

  def print(readably = true)
    strings = []
    for item in data
      strings.push(item.print(readably))
      #strings.push(item.is_a?(Proc) ? print_proc() : item.print(readably))
    end
    return "(" + strings.join(" ") + ")"
  end

  def length()
    return @data.length
  end

  # FIXME - We may need to reinstate this if we go for allowing
  # Procs to filter through  as far as print() above.
  #def print_proc()
  #  return "<#builtin>"
  #end

end

class MalVector < MalList

  def initialize()
    @type = "MalVector"
    @data = []
  end

  def print(readably = true)
    strings = []
    for item in data
      strings.push(item.print(readably))
    end
    return "[" + strings.join(" ") + "]"
  end

end

class MalHashMap < MalList

  def initialize()
    @type = "MalHashMap"
    @data = []
  end

# FIXME
# We should be doing it like this:
#  def push(key, val)
#    @data.push(key)
#    @data.push(val)
#  end
# Instead, we are cheating, and doing it like this, while keeping count
# of items over in reader.rb. Surely this is not the way.
  def push(item)
    @data.push(item)
  end


  def print(readably = true)
    strings = []
    for item in data
      strings.push(item.print(readably))
    end
    return "{" + strings.join(" ") + "}"
  end
end

class MalKeyword < MalType

  def initialize(data)
    @type = "MalKeyword"
    @data = data
    # Prepend ':' if not given
    if @data[0] != ":"
      @data = ":" + @data
    end
  end

end

class MalSymbol < MalType

  def initialize(data)
    @type = "MalSymbol"
    @data = data
  end

end

class MalNumber < MalType

  def initialize(data)
    @type = "MalNumber"
    @data = data.to_i # FIXME AHEM
  end

  # We didn't need either of these after all.
  # Keeping here for now, though, because we may need to revisit the way we
  # convert from Mal data types to types we can actualy process.
  #def to_i
  #  return data.to_i
  #end

  #def to_s
  #  return data.to_s
  #end

end
