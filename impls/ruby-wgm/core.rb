# core.rb

# Define our core functions here
module MalCore
  Env = {
    '+'      => lambda { |x,y| MalNumber.new(x.data + y.data) },
    '-'      => lambda { |x,y| MalNumber.new(x.data - y.data) },
    '*'      => lambda { |x,y| MalNumber.new(x.data * y.data) },
    '/'      => lambda { |x,y| MalNumber.new(x.data / y.data) }, # NB Divide by zero caught by Ruby, not us
    'prn'    => lambda { |*x| strs = x.map { |s| pr_str(s, true) }
                              puts(strs.join(" "))
                              return MalNil.new()
                       },
    'println'=> lambda { |*x| strs = x.map { |s| pr_str(s, false) }
                              puts(strs.join(" "))
                              return MalNil.new()
                       },
    'pr-str' => lambda { |*x| strs = x.map { |s| pr_str(s, true) }
                              return(MalString.new(strs.join(" "), false))
                       },
    'str'    => lambda { |*x| strs = x.map { |s| pr_str(s, false) }
                              return(MalString.new(strs.join(""), false))
                           },
    'list'   => lambda { |*x| l = MalList.new()
                              x.each { |i| l.push(i) }
                              return l
                       },
    'list?'  => lambda { |x| x.instance_of?(MalList) ? MalTrue.new() : MalFalse.new() },
    'empty?' => lambda { |x| x.data.length == 0 ? MalTrue.new() : MalFalse.new() },
    'count'  => lambda { |x| x.is_a?(MalNil) ? 0 : x.data.length },
    '='      => lambda { |x,y| # We must treat MalList and MalVector as equivalent
                               if ((x.instance_of?(MalList) || x.instance_of?(MalVector)) &&
                                   (y.instance_of?(MalList) || y.instance_of?(MalVector)))
                                 return MalFalse.new unless x.length == y.length
                                 x.data.each_with_index { |item, idx|
                                   if (item.is_a?(MalList))
                                     return MalFalse.new() unless MalCore::Env['='].call(item, y.data[idx])
                                   else
                                     return MalFalse.new if item.data != y.data[idx].data
                                   end
                                 }
                               elsif (x.class != y.class)
                                 return MalFalse.new()
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
