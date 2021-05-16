#!/usr/bin/env ruby
# frozen_string_literal: true

# types.rb

# Classes to define the different types we support in Mal

require_relative 'errors'

KEYWORD_PREFIX = "\u029e" # Not wholly sure about this.

# MalType is the base class for our class types
class MalType
  attr_reader :type, :data

  def initialize
    @type = 'MalBaseType'
    @data = nil
  end

  def print(*)
    return @data
  end
end

class MalAtom < MalType
  attr_reader :type, :data

  # data must be a Mal object
  def initialize(data)
    super()
    @type = 'MalAtom'
    @data = data
  end

  # Produce output indicated by the test case
  def print(*)
    return "(atom #{@data.print})"
  end

  # deref
  # Allows us to implement deref so it only works on MalAtoms
  # NB Don't give any other MalObject a deref method.
  def deref
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
    fn = arr.shift
    args = arr.unshift(@data)
    @data = if fn.is_a?(MalFunction)
              fn.call(args)
            else
              fn.call(*args)
            end
  end
end

# MalFunction
# Tee hee
class MalFunction < MalType
  attr_reader :ast, :params, :env, :closure, :data
  attr_accessor :is_macro, :metadata

  def initialize(ast, params, env, closure)
    super()
    @type = 'MalFunction'
    @ast = ast
    @params = params
    @env = env
    @closure = closure
    @is_macro = false
    @metadata = MalNil.new
  end

  # #<function> is what the guide says to do
  # It would be nice to have a way of reading the function back too somehow.
  def print(*)
    return '#<function>'
  end

  # This way we don't have to access @closure directly
  def call(args)
    return @closure.call(*args)
  end

  # def
  # Return a duplicate of ourselves
  # Needed for with-meta and defmacro!
  def dup
    ret = MalFunction.new(ast, params, env, closure)
    ret.is_macro = is_macro
    ret.metadata = metadata
    return ret
  end
end

# MalString
# Here be dragons
class MalString < MalType
  # By default we sanitise our string inputs
  # But when we print from core.rb, we don't want to, so from there
  # we call with the sanitise flag set to false.
  def initialize(data, sanitise: true)
    super()
    @type = 'MalString'
    @data = data
    @data = _sanitise(@data) if sanitise
  end

  def print(readably: true)
    return _unmunge(@data) if readably

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
    raise MalMismatchQuotesError if (m = /(\\+)$/.match(str)) && m[0].length.odd?
  end

  # _single_quote_check
  # Raise an error if all we have is a lone quote
  def _single_quote_check(str)
    raise MalMismatchQuotesError if str == '"'
  end

  # _trailing_quote_check
  # Check there /is/ a trailing quote at the end of the string
  # Raise an error if not
  def _trailing_quote_check(str)
    raise MalMismatchQuotesError unless /"$/.match(str)
  end

  # _unescaped_quote_check
  # Run this after we have stripped our leading and trailing quotes.
  def _unescaped_quote_check(str)
    raise MalMisMatchQuotesError if /[^\\]"/.match(str)
  end

  # _strip_quotes
  # Remove quotes from beginning and end of string
  # We are only called with strings that begin with quotes
  # We call this after checking there is a trailing quote
  def _strip_quotes(str)
    nqstr = str.dup
    nqstr.sub!(/^"/, '')
    nqstr.sub!(/"$/, '')
    return nqstr
  end

  # _munge and _unmunge handle our backslash escaping 'sensibly'
  # \" => "
  # \\ => \
  # \n => actual newline
  def _munge(str)
    mstr = str.dup
    mstr.gsub!(/\\\\/, '{esc-bs}')
    mstr.gsub!(/\\"/, '"')
    mstr.gsub!(/\\n/, "\n")
    mstr.gsub!('{esc-bs}', '\\')
    return mstr
  end

  def _unmunge(str)
    umstr = str.dup
    umstr.gsub!(/(\\)/, '\\1\\1') # MUST do this first
    umstr.gsub!(/\n/, '\\n')
    umstr.gsub!(/"/, '\\"')
    return "\"#{umstr}\""
  end
end

# NB - consider having MalBoolean for both true and false?
class MalTrue < MalType
  def initialize
    super()
    @type = 'MalTrue'
    @data = true
  end

  def print(*)
    return 'true'
  end
end

class MalFalse < MalType
  def initialize
    super()
    @type = 'MalFalse'
    @data = false
  end

  def print(*)
    return 'false'
  end
end

class MalNil < MalType
  def initialise
    super()
    @type = 'MalNil'
    @data = nil
  end

  def print(*)
    return 'nil'
  end
end

class MalList < MalType
  attr_accessor :metadata

  def initialize
    super()
    @type = 'MalList'
    @data = []
    @metadata = MalNil.new
  end

  def push(item)
    @data.push(item)
  end

  def print(readably: true)
    strings = []
    data.each do |item|
      strings.push(item.print(readably: readably))
    end
    return "(#{strings.join(' ')})"
  end

  def length
    return @data.length
  end

  # dup
  # Needed for with-meta
  def dup
    new = MalList.new
    data.each { |i| new.push(i) }
    return new
  end
end

class MalVector < MalList
  def initialize
    super()
    @type = 'MalVector'
    @data = []
    @metadata = MalNil.new
  end

  def print(readably: true)
    strings = []
    data.each do |item|
      strings.push(item.print(readably: readably))
    end
    return "[#{strings.join(' ')}]"
  end

  # dup
  # Needed for with-meta
  def dup
    new = MalVector.new
    data.each { |i| new.push(i) }
    return new
  end
end

class MalHashMap < MalType
  attr_accessor :metadata

  def initialize
    super()
    @type = 'MalHashMap'
    @data = {}
    @next_is_key = true
    @last_key = nil
    @metadata = MalNil.new
  end

  # make_internal_key
  # Utility function to make internal keys
  def make_internal_key(key)
    return key.data if key.is_a?(MalString)

    return key.unimunge if key.is_a?(MalKeyword)

    return key.dup if key.is_a?(String)

    throw "MalHashMap got weird internal key #{key}"
  end

  # return_internal_key
  # Utility function to convert internal representation
  # back into MalTypes for external usage
  def return_internal_key(key)
    return MalKeyword.new(key[1..-1]) if key[0] == KEYWORD_PREFIX

    return MalString.new(key.dup, sanitise: false) # NB key.dup as string may be frozen
  end

  # grab_keys
  # A sortof wrapper around Ruby's keys that unmunges our internal munging
  # for external usage.
  def grab_keys
    ret_arr = []
    @data.each_key { |k| ret_arr.push(return_internal_key(k)) }
    return ret_arr
  end

  # push
  # Not sure if we should keep this around
  # Might make life easier: allows us to use sequential push elsewhere
  # to populate hashes, so long as we trust that we are always getting
  # an even number of key,val pairs, or we will corrupt ourselves.
  def push(item)
    if @next_is_key
      if item.is_a?(MalString) || item.is_a?(MalKeyword)
        ikey = make_internal_key(item)
        @data[ikey] = nil
        @last_key = ikey
      else
        @data[item] = nil
        @last_key = item
      end
    else
      @data[@last_key] = item
      @last_key = nil
    end
    @next_is_key = !@next_is_key
  end

  # exists
  # Take a key
  # Return true if we have such a key, false if not
  def exists(key)
    ikey = make_internal_key(key)
    return @data.has_key?(ikey)
  end

  # set
  # Take a key and a value
  # Convert input to our internal key representation
  # Set key to value
  def set(key, val)
    ikey = make_internal_key(key)
    @data[ikey] = val
  end

  # get
  # Return a key's value if it exists
  # Else return MalNil
  # Accept both raw strings and MalTypes
  def get(key)
    ikey = make_internal_key(key)
    return @data[ikey] if @data.has_key?(ikey)

    return MalNil.new
  end

  # print
  # Zip our keys with their values, flatten that
  # then treat it all as an array for ease of processing.
  # FIXME Is this really a good idea / idiomatic? Or idiotic?
  # FIXME Shouldn't we just use return_internal_key here?
  def print(readably: true)
    strings = []
    munge = @data.keys.zip(@data.values).flatten
    munge.each do |item|
      if item.is_a?(MalType)
        strings.push(item.print(readably: readably))
      elsif item[0] == KEYWORD_PREFIX # magic MalKeyword prefix
        strings.push(item[1..-1])
      else
        strings.push("\"#{item}\"")
      end
    end
    return "{#{strings.join(' ')}}"
  end

  # dup
  # Needed for with-meta
  def dup
    new = MalHashMap.new
    grab_keys.each { |k| new.set(k, data[k]) }
    return new
  end
end

class MalKeyword < MalType
  def initialize(data)
    super()
    @type = 'MalKeyword'
    @data = data
    # Prepend ':' if not given
    @data = ":#{@data}" if @data[0] != ':'
  end

  def unimunge
    return KEYWORD_PREFIX + data
  end
end

class MalSymbol < MalType
  def initialize(data)
    super()
    @type = 'MalSymbol'
    @data = data
  end
end

class MalNumber < MalType
  def initialize(data)
    super()
    @type = 'MalNumber'
    @data = data.to_i # FIXME: We should also handle non-integers
  end
end
