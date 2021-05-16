# frozen_string_literal: true

# printer.rb

# Convert our mal data type back to a string

# pr_str
# Takes our mal data object
# Returns a string representation
# Each data type knows how to print itself
def pr_str(mal_data, readably: true)
  return nil if mal_data.nil?

  return mal_data.print(readably: readably)
end
