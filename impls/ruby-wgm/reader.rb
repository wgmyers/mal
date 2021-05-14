#!/usr/bin/env ruby

# reader.rb

# Parses and tokenises input into data structure
# Data structure is defined in types.rb

require_relative 'types'
require_relative 'errors'

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
    return true if @open == @close
    return false
  end

  def goodhash
    return true if @hashcount.even?
    return false
  end

end

# read_atom, read_list and read_form are the core of our parser
# Works sorta kinda, but!!!
# FIXME does not yet reliably return error on mismatched parens.

def read_atom(reader, matcher)
  data = reader.peek()
  case data
  when nil
    retval = nil
  when ')'
    retval = ')'
  when ']'
    retval = ']'
  when '}'
    retval = '}'
  when /^-?\d+$/
    retval = MalNumber.new(data)
  when /^\"/
    retval = MalString.new(data)
  when /^:/
    retval = MalKeyword.new(data)
  when 'true'
    retval = MalTrue.new
  when 'false'
    retval = MalFalse.new
  when 'nil'
    retval = MalNil.new
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
  when '('
    retval = MalList.new
  when '['
    retval = MalVector.new
  when '{'
    retval = MalHashMap.new
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
      matcher.hashcount() if ishash
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
    if (retval == ')' || retval == ']' || retval == '}')
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

# expand_macros
# Take our token array
# Run through looking for reader macros specified in step1_read_print.mal
# '  = quote
# `  = quasiquote
# ~  = unquote
# ~@ = splice-unquote
# @  = deref
# Expand them.
# NB: Macros can nest: in_macro and in_brackets count how deep we are in.
# last_was_macro tracks if the last token we saw was a macro
# FIXME This code should be less ugly than it is. It is *fugly*.
def expand_macros(tok_arr)
  ret_arr = []
  in_macro = 0
  in_brackets = 0
  last_was_macro = false

  for item in tok_arr
    case item
    # Handle splice-unquote
    when '~@'
      ret_arr.push('(')
      ret_arr.push('splice-unquote')
      in_macro = in_macro + 1
      last_was_macro = true
    # Handle quote, quasiquote, unquote and deref
    when /^[\'|`|~|@]$/
      ret_arr.push('(')
      case item
      when "\'"
        ret_arr.push('quote')
      when '`'
        ret_arr.push('quasiquote')
      when '~'
        ret_arr.push('unquote')
      when '@'
        ret_arr.push('deref')
      end
      in_macro = in_macro + 1
      last_was_macro = true
    else
      if in_macro > 0
        case item
        # When we're in a macro, we need to start counting brackets
        when '(', '['
          ret_arr.push(item)
          in_brackets = in_brackets + 1
        else
          if in_brackets > 0
            if (item == ')') || (item == ']')
              ret_arr.push(item)
              ret_arr.push(')')
              in_brackets = in_brackets - 1
              in_macro = in_macro - 1
            else
              ret_arr.push(item)
              # Handle nested macros+brackets here.
              # * If macro depth is greater than bracket depth, we have an
              # unbracketed macro inside a bracketed one, and we need to end it
              # and decrease macro count.
              # Nested bracketed macros should Just Work.
              # * But if last_was_macro is true, we're the first item after the
              # last macro, so we should also end it
              if (in_brackets < in_macro) || last_was_macro
                ret_arr.push(')')
                in_macro = in_macro - 1
              end
            end
          else
            ret_arr.push(item)
            # We're not in brackets. End all open macros now.
            while in_macro > 0
              ret_arr.push(')')
              in_macro = in_macro - 1
            end
          end # if in_brackets > 0
        end
      else
        ret_arr.push(item)
      end # if in_macro
      last_was_macro = false
    end   # case item
  end     # item in tok_arr
  return ret_arr
end

# expand_metadata
# The ^ macro for metadata is handled differently from the others.
# It takes the following two items, rearranges them, and places both in
# a new list prefixed with 'with-meta'
# ^{"a" 1} [1 2 3]
# (with-meta [1 2 3] {"a" 1})
# The expand_macros function above is horrible enough without trying to
# splice this in as well. The below is likely to be horrible too.
def expand_metadata(tok_arr)
  ret_arr = []
  in_macro = false
  item_one_arr = []
  item_two_arr = []
  item_count = 0
  cur_bracket = ''
  bracket_depth = 0
  for item in tok_arr
    case item
    when '^'
      # We found a metadata macro
      # If we are already in one, blow up. We aren't nesting these.
      raise MalNestedWithMetaError if in_macro
      in_macro = true
      item_count = 2
      ret_arr.push('(')
      ret_arr.push('with-meta')
    else
      if in_macro
        # If we haven't seen two items, start counting brackets
        # and saving the items into our two item arrays
        # When we've seen as many opening as closing brackets, we have
        # (probably) seen a complete item. Either go onto the next, or
        # add both items to the main array and complete the macro.
        if item_count > 0
          bracket_depth += 1 if /^[\(\[\{]$/.match(item)
          bracket_depth -= 1 if /^[\)\]\}]$/.match(item)
          if item_count == 2
            item_one_arr.push(item)
          elsif item_count == 1
            item_two_arr.push(item)
          end
          item_count -= 1 if bracket_depth == 0
        end
        if item_count == 0
          in_macro = false
          ret_arr.push(item_two_arr)
          ret_arr.push(item_one_arr)
          ret_arr.push(')')
          ret_arr.flatten!
        end
      else
        ret_arr.push(item)
      end
    end
  end
  return ret_arr
end

# drop_comments
# Seems our tokenizer does our comment munging for us
# So if we drop all tokens beginning with ';' we should be ok. Right? Hrm.
def drop_comments(tok_arr)
  ret_arr = []
  tok_arr.each { |item| ret_arr.push(item) unless item[0] == ';' }
  return ret_arr
end


# read_str
# Take a string, and call tokenize on it
# Then create a new Reader with those tokens
# Then call read_form with that Reader
# Presumably, we then return the output of that? Guide does not say.
def read_str(str)
  tokens = tokenize(str)
  tokens = drop_comments(tokens)
  tokens = expand_metadata(tokens)
  tokens = expand_macros(tokens)
  reader = Reader.new(tokens)
  matcher = Matcher.new
  retval = read_form(reader, matcher)
  # Check our parentheses have matched and our hashmaps are ok
  begin
    if matcher.goodhash
      if matcher.matched
        return retval
      else
        raise MalMismatchParensError
      end
    else
      raise MalBadHashMapError
    end
  rescue MalBadHashMapError, MalMismatchParensError => e
    raise e
  end
end

# Some tests

if __FILE__ == $0
  t1 = read_str('123')
  p t1
  t2 = read_str('( 123 )')
  p t2
  t3 = read_str('(123 456)')
  p t3
  t4 = read_str('( + 1 ( * 2 3 ) )')
  p t4
end
