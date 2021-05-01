#!/usr/bin/env ruby

# types.rb

# Classes to define the different types we support in Mal

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
