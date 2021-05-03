#!/usr/bin/env ruby

# printer.rb

# Convert our mal data type back to a string

# pr_str
# Takes our mal data object
# Returns a string representation
# Each data type knows how to print itself
def pr_str(mal_data, readably = true)
  return mal_data.print(readably)
end

#  is_list = false
#  strings = []
#  if mal_data.kind_of?(MalSymbol) || mal_data.kind_of?(MalNumber)
#    strings.push(mal_data.data)
#  elsif mal_data.kind_of?(MalList)
#    is_list = true
#    for item in mal_data.data
#      if item.kind_of?(MalList)
#        strings.push(pr_str(item))
#      else
#        strings.push(item.data)
#      end
#    end
#  else
#    raise ("Unknown data type")
#  end
#  if is_list
#    return "(" + strings.join(" ") + ")"
#  else
#    return strings.join(" ")
#  end
#end
