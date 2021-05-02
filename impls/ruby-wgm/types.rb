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

  def print()
    return @data
  end

end

# MalString
# Here be dragons
class MalString < MalType

  def initialize(data)
    @type = "MalString"
    @data = _munge(data)
    # FIXME does not actually work, "\\" is ok but gets caught.
    if !(/[^\\]\"$/.match(@data))
      raise MalMismatchQuotesError
    end
  end

  def print(readably = true)
    if readably
      return _unmunge(@data)
    end
    return @data
  end

  # _munge and _unmunge handle our backslash escaping 'sensibly'
  # \" => "
  # \\ => \
  # \n => actual newline
  # FIXME does not actually work, many tests failed.
  def _munge(str)
    str.gsub!(/\\\"/, "\"")
    str.gsub!(/\\\\/, "\\")
    str.gsub!(/\\n/, "\n")
    return str
  end

  def _unmunge(str)
    str.gsub!(/\n/, "\\n")
    str.gsub!(/\\/, "\\\\")
    str.gsub!(/(.+)\"(.+)/, "\\1\\\"\\2") # Don't match tops and tails
    return str
  end

end

# NB - consider having MalBoolean for both true and false?
class MalTrue < MalType

  def initialize()
    @type = "MalTrue"
    @data = true
  end

  def print()
    return  "true"
  end

end
class MalFalse < MalType

  def initialize()
    @type = "MalFalse"
    @data = false
  end

  def print()
    return "false"
  end

end

class MalNil < MalType

  def initialise()
    @type = "MalNil"
    @data = nil
  end

  def print()
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

  def print()
    strings = []
    for item in data
      strings.push(item.print())
    end
    return "(" + strings.join(" ") + ")"
  end

end

class MalVector < MalList

  def initialize()
    @type = "MalVector"
    @data = []
  end

  def print
    strings = []
    for item in data
      strings.push(item.print())
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


  def print
    strings = []
    for item in data
      strings.push(item.print())
    end
    return "{" + strings.join(" ") + "}"
  end
end

class MalKeyword < MalType

  def initialize(data)
    @type = "MalKeyword"
    @data = data
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
    @data = data
  end

end
