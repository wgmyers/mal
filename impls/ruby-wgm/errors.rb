# errors.rb

# Custom exception classes for errors.
# NB - Inherit from StandardError and not Exception or things don't work.

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

class MalBadHashMapError < StandardError
  def initialize(msg = "Number of keys does not match number of values in hashmap")
    super(msg)
  end
end

class MalUnknownListTypeError < StandardError
  def initialize(msg = "Unknown list type before EOF")
    super(msg)
  end
end
