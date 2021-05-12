# errors.rb

# Custom exception classes for errors.
# NB - Inherit from StandardError and not Exception or things don't work.

class MalBadApplyError < StandardError
  def initialize(msg = "Malformed call to 'apply'")
    super(msg)
  end
end

class MalBadEnvError < StandardError
  def initialize(msg = "Number of binds must match number of exprs in env creation")
    super(msg)
  end
end

class MalBadHashMapError < StandardError
  def initialize(msg = "Number of keys does not match number of values in hashmap")
    super(msg)
  end
end

class MalBadMapError < StandardError
  def initialize(msg = "Malformed call to 'map'")
    super(msg)
  end
end

class MalBadPromptError < StandardError
  def initialize(msg = "arg to readline must be string")
    super(msg)
  end
end

class MalIndexOutOfRangeError < StandardError
  def initialize(msg = "'nth' index out of bounds")
    super(msg)
  end
end

class MalMetaError < StandardError
  def initialize(msg = "only lists, vectors, hashes and functions take metadata")
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

class MalNotImplementedError < StandardError
  def initialize(msg = "Function not implemented")
    super(msg)
  end
end

class MalSeqError < StandardError
  def initialize(msg = "arg to seq must be string, list, vector or nil")
    super(msg)
  end
end

class MalThrownError < StandardError
  attr_reader :malexp
  def initialize(msg = "Error thrown by Mal throw built-in", malexp: nil)
    super(msg)
    @malexp = malexp
  end
end

class MalTryCatchError < StandardError
  def initialize(msg = "try*/catch* block caught error")
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
