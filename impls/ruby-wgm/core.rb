# core.rb

# Define our core functions here
module MalCore
  Env = {
    '+'      => lambda { |x,y| MalNumber.new(x.data + y.data) },
    '-'      => lambda { |x,y| MalNumber.new(x.data - y.data) },
    '*'      => lambda { |x,y| MalNumber.new(x.data * y.data) },
    '/'      => lambda { |x,y| MalNumber.new(x.data / y.data) }, # NB Divide by zero caught by Ruby, not us
    'prn'    => lambda { |x| puts(pr_str(x, true))
                             return MalNil.new()
                       },
    'list'   => lambda { |*x| l = MalList.new()
                              x.each { |i| l.push(i) }
                              return l
                       },
    'list?'  => lambda { |x| x.is_a?(MalList) ? MalTrue.new() : MalFalse.new() },
    'empty?' => lambda { |x| x.data.length == 0 ? MalTrue.new() : MalFalse.new() },
    'count'  => lambda { |x| x.is_a?(MalNil) ? 0 : x.data.length },
    '='      => lambda { |x,y| if (x.class != y.class)
                                 return MalFalse.new()
                               end
                               if (x.is_a?(MalList) || x.is_a?(MalVector))
                                 return MalFalse.new if x.length != y.length
                                 x.data.each_with_index { |item, idx|
                                   return MalFalse.new if item.data != y.data[idx].data
                                 }
                               elsif (x.data != y.data)
                                 return MalFalse.new()
                               end
                               return MalTrue.new()
                       },
    '<'      => lambda { |x,y| x.data < y.data ? MalTrue.new() : MalFalse.new() },
    '<='     => lambda { |x,y| x.data <= y.data ? MalTrue.new() : MalFalse.new() },
    '>'      => lambda { |x,y| x.data > y.data ? MalTrue.new() : MalFalse.new() },
    '>='     => lambda { |x,y| x.data >= y.data ? MalTrue.new() : MalFalse.new() },
  }
  Mal = {
    'not' => '(def! not (fn* (a) (if a false true)))'
  }
end
