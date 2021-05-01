#!/usr/bin/env ruby

# types.rb

# Classes to define the different types we support in Mal

# MalType is the base class for our class types
class MalType

  attr_reader :name, :data

  def initialize()
    @name = "BaseType"
    @data = nil
  end

end

class MalList < MalType

  def initialize()
    @name = "List"
    @data = []
  end

  def push(item)
    @data.push(item)
  end

end

class MalSymbol < MalType

  def initialize(data)
    @name = "Symbol"
    @data = data
  end

end

class MalNumber < MalType

  def initialize(data)
    @name = "Number"
    @data = data
  end

end
