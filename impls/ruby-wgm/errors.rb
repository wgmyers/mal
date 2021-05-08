# errors.rb

# Custom exception classes for errors.
# NB - Inherit from StandardError and not Exception or things don't work.

class MalBadEnvError < StandardError
  def initilize(msg = "Number of binds must match number of exprs in env creation")
    super(msg)
  end
end

class MalBadHashMapError < StandardError
  def initialize(msg = "Number of keys does not match number of values in hashmap")
    super(msg)
  end
end

class MalIndexOutOfRangeError < StandardError
  def initialize(msg = "nth called with index larger than size of list")
    super(msg)
  end
end

class MalMismatchParensError < StandardError
  def initialize(msg = "Mismatched parentheses at EOF")
    super(msg)
  end
end

class MalMismatchQuotesError < StandardError
  def initialize(msg = "Mismatched quotes at EOF")
    super(msg)
  end
end

class MalNestedWithMetaError < StandardError
  def initialize(msg = "Nested ^/with-meta macros not supported")
    super(msg)
  end
end

class MalUnknownSymbolError < StandardError
  def initialize(msg = "Symbol not found.")
    super(msg)
  end
end

class MalUnknownListTypeError < StandardError
  def initialize(msg = "Unknown list type before EOF")
    super(msg)
  end
end
