#!/usr/bin/env ruby

# printer.rb

# Convert our mal data type back to a string

# pr_str
# Takes our mal data
# Iterates through it, converting back to string
# Returns that string
def pr_str(mal_data)
  strings = []
  # Handle degenerate case where we have a raw string
  if !mal_data.kind_of?(Array)
    return mal_data
  end
  # Ok, it's an array, handle that
  for item in mal_data
    if item.kind_of?(Array)
      strings.push(pr_str(item))
    else
      strings.push(item)
    end
  end
  return "(" + strings.join(" ") + ")"
end
