# errors.rb

# Custom exception classes for errors.
# NB - Inherit from StandardError and not Exception or things don't work.

class MalMismatchParensError < StandardError
  def initialize(msg = "Mismatched parentheses at EOF")
    super(msg)
  end
end