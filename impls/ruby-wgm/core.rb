# core.rb

# Define our core functions here
module MalCore
  Env = {
    '+'           => lambda { |x,y| MalNumber.new(x.data + y.data) },
    '-'           => lambda { |x,y| MalNumber.new(x.data - y.data) },
    '*'           => lambda { |x,y| MalNumber.new(x.data * y.data) },
    '/'           => lambda { |x,y| MalNumber.new(x.data / y.data) }, # NB Divide by zero caught by Ruby, not us
    'prn'         => lambda { |*x| strs = x.map { |s| pr_str(s, true) }
                              puts(strs.join(" "))
                              return MalNil.new()
                            },
    'println'     => lambda { |*x| strs = x.map { |s| pr_str(s, false) }
                              puts(strs.join(" "))
                              return MalNil.new()
                            },
    'pr-str'      => lambda { |*x| strs = x.map { |s| pr_str(s, true) }
                              return(MalString.new(strs.join(" "), false))
                            },
    'str'         => lambda { |*x| strs = x.map { |s| pr_str(s, false) }
                              return(MalString.new(strs.join(""), false))
                            },
    'list'        => lambda { |*x| l = MalList.new()
                              x.each { |i| l.push(i) }
                              return l
                            },
    'list?'       => lambda { |x| x.instance_of?(MalList) ? MalTrue.new() : MalFalse.new() },
    'empty?'      => lambda { |x| x.data.length == 0 ? MalTrue.new() : MalFalse.new() },
    'count'       => lambda { |x| x.is_a?(MalNil) ? 0 : x.data.length },
    '='           => lambda { |x,y| # We must treat MalList and MalVector as equivalent
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
    '<'           => lambda { |x,y| x.data < y.data ? MalTrue.new() : MalFalse.new() },
    '<='          => lambda { |x,y| x.data <= y.data ? MalTrue.new() : MalFalse.new() },
    '>'           => lambda { |x,y| x.data > y.data ? MalTrue.new() : MalFalse.new() },
    '>='          => lambda { |x,y| x.data >= y.data ? MalTrue.new() : MalFalse.new() },
    'read-string' => lambda { |x| return read_str(x.print(false)) },
    'slurp'       => lambda { |x| return MalString.new(File.read(x.print(false)), false) }, # FIXME Error checking?
    'atom'        => lambda { |x| return MalAtom.new(x) },
    'atom?'       => lambda { |x| return x.is_a?(MalAtom) },
    'deref'       => lambda { |x| return x.deref() },
    'reset!'      => lambda { |x,y| return x.reset(y) },
    'swap!'       => lambda { |x,*y| return x.swap(y) },
    'cons'        => lambda { |x,y| # NB - Original list y must be unchanged.
                                  z = MalList.new()
                                  z.push(x)
                                  y.data.each { |i| z.push(i) }
                                  return z
                            }, # FIXME Error checking?
    'concat'      => lambda { |*x|
                                  y = MalList.new()
                                  x.each { |l|
                                    l.data.each { |i| y.push(i) }
                                  }
                                  return y
                            }, # FIXME Error checking? What if not list?
    'vec'         => lambda { |x|
                                  if x.is_a?(MalVector)
                                    return x
                                  end
                                  y = MalVector.new()
                                  x.data.each { |i| y.push(i) }
                                  return y
                            }, # FIXME Error checking? What if not list or vector?
    'nth'         => lambda { |x,y|
                                    if y >= x.data.length
                                      raise MalIndexOutOfRangeError
                                    end
                                    return x.data[y]
                            }, # FIXME Error checking? What if not list or vector?
  }
  Mal = {
    'not' => '(def! not (fn* (a) (if a false true)))',
    'load-file' => '(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) "\nnil)")))))'
  }
end
