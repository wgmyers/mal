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
class Matcher

  attr_reader :open, :close

  def initialize()
    @open = 0
    @close = 0
  end

  def open
    @open = @open + 1
  end

  def close
    @close = @close + 1
  end

  def matched
    if @open == @close
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
  when /-?\d+/
    retval = MalNumber.new(data)
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

def read_list(reader, matcher)
  retval = MalList.new()
  reader.next()
  loop do
    res = read_form(reader, matcher)
    case res
    when ")"
      break
    when nil
      break
    else
      retval.push(res)
      reader.next()
    end
  end
  return retval
end

def read_form(reader, matcher)
  cur_tok = reader.peek()
  case cur_tok
  when "("
    matcher.open()  # Count our open parentheses
    retval = read_list(reader, matcher)
  else
    retval = read_atom(reader, matcher)
    if retval == ")"
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
  #p matcher
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
