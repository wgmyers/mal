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
                              return MalNil.new() # NB - return nil instead to suppress 'nil' print
                            },
    'println'     => lambda { |*x| strs = x.map { |s| pr_str(s, false) }
                              puts(strs.join(" "))
                              return MalNil.new() # NB - same as above.
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
                                    if y.data >= x.data.length
                                      raise MalIndexOutOfRangeError
                                    end
                                    return x.data[y.data]
                            }, # FIXME Error checking? What if not list or vector?
    'first'       => lambda { |x| (!x.is_a?(MalNil) && (x.data.length > 0)) ? x.data[0] : MalNil.new() },
    'rest'        => lambda { |x|
                                  y = MalList.new()
                                  return y unless !x.is_a?(MalNil) # back out now if x is nil
                                  x.data.drop(1).each { |i| y.push(i) }
                                  return y
                            },
    'throw'       => lambda { |x| x.is_a?(MalString) ? (raise MalThrownError, x.data) : (raise MalThrownError) },
    'apply'       => lambda { |f, *ins|
                                  if !(f.is_a?(MalFunction) || f.is_a?(Proc)) ||
                                     !ins[-1].is_a?(MalList)
                                    raise MalBadApplyError
                                  end
                                  argsl = ins.pop()
                                  ins.reverse.each { |i| argsl.data.unshift(i) }
                                  if f.is_a?(Proc) # handle builtins
                                    return f.call(*argsl.data)
                                  end
                                  return f.call(argsl.data)
                            },
    'map'         => lambda { |f, ins|
                                  if !(f.is_a?(MalFunction) || f.is_a?(Proc)) ||
                                     !ins.is_a?(MalList)
                                    raise MalBadMapError
                                  end
                                  y = MalList.new()
                                  ins.data.each { |i| f.is_a?(Proc) ? y.push(f.call(*i)) : y.push(f.call(i)) }
                                  return y
                            },
    'nil?'        => lambda { |x| x.is_a?(MalNil) ? true : false }, # FIXME Why aren't we returning MalType here? Why does it still work?
    'true?'       => lambda { |x| x.is_a?(MalTrue) ? true : false }, # Same...
    'false?'      => lambda { |x| x.is_a?(MalFalse) ? true : false }, # Etc...
    'symbol?'     => lambda { |x| x.is_a?(MalSymbol) ? true : false },
    'symbol'      => lambda { |x| MalString.new(x.data) },
    'keyword'     => lambda { |x| MalKeyword.new(x.data) },
    'keyword?'    => lambda { |x| x.is_a?(MalKeyword) ? true : false },
    'vector'      => lambda { |*x|
                                   y = MalVector.new()
                                   x.each { |i| y.push(i) }
                                   return y
                            },
    'vector?'     => lambda { |x| x.is_a?(MalVector) ? true : false },
    'sequential?' => lambda { |x| (x.is_a?(MalVector) || x.is_a?(MalList)) ? true : false },
    'hash-map'    => lambda { |*x|
                                  if !x.length.even?
                                    raise MalBadHashMapError
                                  end
                                  y = MalHashMap.new()
                                  x.each { |i| y.push(i) }
                                  return y
                            },
    'map?'        => lambda { |x| x.is_a?(MalHashMap) ? true : false },
    'assoc'       => lambda { |h, *kv|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "first arg to 'assoc' must be hash"
                                  end
                                  if !kv.length.even?
                                    raise MalBadHashMapError
                                  end
                                  y = MalHashMap.new()
                                  h.data.each { |i| y.push(i) }
                                  kv.each { |i| y.push(i) }
                                  return y
                            },
    'dissoc'      => lambda { |h,l|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "first arg to 'dissoc' must be hash"
                                  end
                                  if !l.is_a?(MalList)
                                    # FIXME Really MalBadHashMapError?
                                    raise MalBadHashMapError, "second arg to 'dissoc' must be list"
                                  end
                                  y = MalHashMap.new()
                                  h.data.keys.each { |k|
                                                        if true # FIXME
                                                          y.set(k, h.get(k))
                                                        end
                                                   }
                                  return y
                            },
    'get'         => lambda { |h,k|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "first arg to 'get' must be hash"
                                  end
                                  return h.get(k)
                            },
    'contains?'   => lambda { |h,k|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "first arg to 'contains?' must be hash"
                                  end
                                  return h.data.has_key?(k)
                            },
    'keys'        => lambda { |h|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "first arg to 'keys' must be hash"
                                  end
                                  y = MalList.new()
                                  h.data.keys.each { |k| y.push(k) }
                                  return y
                            },
    'vals'        => lambda { |h|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "first arg to 'values' must be hash"
                                  end
                                  y = MalList.new()
                                  h.data.values.each { |k| y.push(k) }
                                  return y
                            },
    'macavity'    => lambda { |*x| raise MalNotImplementedError },
  }
  Mal = {
    'not' => '(def! not (fn* (a) (if a false true)))',
    'load-file' => '(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) "\nnil)")))))',
    'cond' => "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list \'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons \'cond (rest (rest xs)))))))"
  }
end
