#!/usr/local/env ruby

# env.rb

#require 'pp'

# Implement a Lisp environment

require_relative "errors"

class Env

  attr_reader :outer, :data

  def initialize(outer = nil, binds = [], exprs = [])
    @outer = outer
    @data = {}

    # First check if we've been given variadic bindings
    variadic = false
    binds.each do |b|
      if b.data == "&"
        variadic = true
        break
      end
    end
    # Sanity check inputs a bit
    if ((binds.length != exprs.length) && !variadic)
      raise MalBadEnvError
    end
    # Variadic binding: if we encounter a "&" we bind the next bind item
    # to all the remaining items in expr.
    if variadic
      #puts "We are variadic!"
      binds.each_with_index do |b, i|
        if b.data == "&"
          # FIXME This does not work at all.
          nl = MalList.new()
          exprs.drop(i).each { |e| nl.push(e) }
          set(binds[i+1], nl)
          break
        else
          set(b, exprs[i])
        end
      end
    else
      binds.zip(exprs) do | bind, expr |
        set(bind, expr)
      end
    end
    #puts "Env.initialize"
    #pp self
  end

  # set
  # Take a key and a value
  # Add them to @data
  # If the key is a MalSymbol, use the data as a key
  # Otherwise go ahead.
  # FIXME This can't be right.
  def set(key, val)
    if key.is_a?(MalSymbol)
      @data[key.data] = val
    else
      @data[key] = val
    end
    return self
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
      raise MalUnknownSymbolError, "Symbol #{key} not found."
    end
  end

end
