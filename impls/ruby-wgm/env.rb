# frozen_string_literal: true

# env.rb

# Implement a Lisp environment

require_relative 'errors'

# Env implements both the core environment we start with
# and, with outer, allows the environment to be changed eg by def! etc
# set allows new bindings to be made
# get will search recursively outward until it finds a match
class Env
  attr_reader :outer, :data

  def initialize(outer = nil, binds = [], exprs = [])
    @outer = outer
    @data = {}

    # First check if we've been given variadic bindings
    variadic = false
    binds.each do |b|
      if b.data == '&'
        variadic = true
        break
      end
    end
    # Sanity check inputs a bit
    raise MalBadEnvError if (binds.length != exprs.length) && !variadic

    # Variadic binding: if we encounter a "&" we bind the next bind item
    # to all the remaining items in expr.
    if variadic
      binds.each_with_index do |b, i|
        if b.data == '&'
          nl = MalList.new
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
    return self if @data.has_key?(key)

    return @outer.find(key) unless @outer.nil?

    return nil
  end

  # get
  # Take a key and use find to get an environment containing it
  # If we find one, return the corresponding value
  # If we don't, throw MalUnknownSymbolError
  def get(key)
    env = find(key)
    return env.data[key] if env

    raise MalUnknownSymbolError, "'#{key}' not found"
  end
end
