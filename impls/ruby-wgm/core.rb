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
    'count'  => lambda { |x| x.data.length },
    '='      => lambda { |x,y| if (x.class != y.class) || (x.data != y.data)
                                 return MalFalse.new()
                               end
                               return MalTrue.new()
                       }, # FIXME does not work on lists :(
    '<'      => lambda { |x,y| x.data < y.data ? MalTrue.new() : MalFalse.new() },
    '<='     => lambda { |x,y| x.data <= y.data ? MalTrue.new() : MalFalse.new() },
    '>'      => lambda { |x,y| x.data > y.data ? MalTrue.new() : MalFalse.new() },
    '>='     => lambda { |x,y| x.data >= y.data ? MalTrue.new() : MalFalse.new() },
  }
end
