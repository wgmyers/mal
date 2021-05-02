#!/usr/bin/env ruby

# reader.rb

# Parses and tokenises input into data structure
# We're Ruby, we're loosely typed, an array will be fine

require_relative "types"
require_relative "errors"

class Reader

  attr_reader :tokens, :pos

  def initialize(token_arr)
    @tokens = token_arr
    @pos = 0
  end

  # next
  # Check if @pos is pointing off the end of the array, return nil if so
  # Otherwise return token at @pos and increment @pos
  # NB - Correct behaviour in case where @pos is too large for array is not
  #      explicitly specified by guide dox, so returning nil is a guess.
  def next
    if @pos == @tokens.length()
      retval = nil
    else
      retval = @tokens[@pos]
      @pos = @pos + 1
    end
    return retval
  end

  # peek
  # Just return the token at current pos
  def peek
    return @tokens[@pos]
  end

end

#  Matcher
# A class to count open and close parens as we read them
# Also counts number of items added to hashmaps
# matched returns true if we counted as many open as close parens
# hashcount returns true if we have an even number of items
class Matcher

  attr_reader :open, :close, :hashcount

  def initialize()
    @open = 0
    @close = 0
    @hashcount = 0
  end

  def open
    @open = @open + 1
  end

  def close
    @close = @close + 1
  end

  def hashcount
    @hashcount = @hashcount + 1
  end

  def matched
    if @open == @close
      return true
    end
    return false
  end

  def goodhash
    if ((@hashcount / 2).to_i == (@hashcount / 2))
      return true
    end
    return false
  end

end

# read_atom, read_list and read_form are the core of our parser
# Works sorta kinda, but!!!
# FIXME does not yet return error on mismatched parens.

def read_atom(reader, matcher)
  data = reader.peek()
  case data
  when nil
    retval = nil
  when ")"
    retval = ")"
  when "]"
    retval = "]"
  when "}"
    retval = "}"
  when /-?\d+/
    retval = MalNumber.new(data)
  when /^\"/
    retval = MalString.new(data)
  when "true"
    retval = MalTrue.new()
  when "false"
    retval = MalFalse.new()
  when "nil"
    retval = MalNil.new()
  else
    retval = MalSymbol.new(data)
  end
  return retval
end

# read_list creates Lists, Vectors and Hashmaps
# For hashmaps, we keep count of how many items have been added in the matcher
# If this is not an even number, we can complain later.
# FIXME 1 - surely we should be squirreling away our keys
# in order to properly match them to values and insert both at once.
# FIXME 2 - Aren't we supposed to check here that hash keys are string or keyword keys?
def read_list(reader, matcher, type)
  ishash = false
  case type
  when "("
    retval = MalList.new()
  when "["
    retval = MalVector.new()
  when "{"
    retval = MalHashMap.new()
    ishash = true
  else
    raise MalUnknownListTypeError
  end
  reader.next()
  loop do
    res = read_form(reader, matcher)
    case res
    when /^[\)\]\}]$/
      break
    when nil
      break
    else
      retval.push(res)
      if ishash
        matcher.hashcount()
      end
      reader.next()
    end
  end
  return retval
end

def read_form(reader, matcher)
  cur_tok = reader.peek()
  case cur_tok
  when /^[\(\[\{]$/
    matcher.open()  # Count our open parentheses
    retval = read_list(reader, matcher, cur_tok)
  else
    retval = read_atom(reader, matcher)
    if (retval == ")" || retval == "]" || retval == "}")
      matcher.close() # Count our close parentheses
    end
  end
  return retval
end

# tokenize
# Take a string
# Run it through a regex to find tokens therein
# Return array  of those tokens
def tokenize(str)
  token_re = /[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"?|;.*|[^\s\[\]{}('"`,;)]*)/
  matches = str.scan(token_re).flatten
  #p matches
  matches.pop # Lose spurious empty string at the end created by str.scan
  return matches
end

# read_str
# Take a string, and call tokenize on it
# Then create a new Reader with those tokens
# Then call read_form with that Reader
# Presumably, we then return the output of that? Guide does not say.
def read_str(str)
  tokens = tokenize(str)
  reader = Reader.new(tokens)
  matcher = Matcher.new()
  retval = read_form(reader, matcher)
  # Check our parentheses have matched
  begin
    if matcher.matched
      return retval
    else
      raise MalMismatchParensError
    end
  rescue MalMismatchParensError => e
    raise e
  end
end

# Some tests

if __FILE__ == $0
  t1 = read_str("123")
  p t1
  t2 = read_str("( 123 )")
  p t2
  t3 = read_str("(123 456)")
  p t3
  t4 = read_str("( + 1 ( * 2 3 ) )")
  p t4
end
