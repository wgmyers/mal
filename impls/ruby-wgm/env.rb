#!/usr/local/env ruby

# env.rb

# Implement a Lisp environment

require_relative "errors"

class Env

  attr_reader :outer, :data

  def initialize(outer = nil)
    @outer = outer
    @data = {}
  end

  # set
  # Take a key and a value
  # Add them to @data
  def set(key, val)
    @data[key] = val
  end

  # find
  # Take a key
  # If current environment contains it, return that
  # Otherwise recurse up the environment tree, looking there
  # Return nil if nothing found
  def find(key)
    if @data.has_key?(key)
      return self
    elsif @outer != nil
      return @outer.find(key)
    end
    return nil
  end

  # get
  # Take a key and use find to get an environment containing it
  # If we find one, return the corresponding value
  # If we don't, throw MalUnknownSymbolError
  def get(key)
    env = find(key)
    if env
      return env.data[key]
    else
      raise MalUnknownSymbolError
    end
  end

end
