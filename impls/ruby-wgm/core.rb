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
                               elsif (x.is_a?(MalHashMap))
                                 # QUERY - Shouldn't we try to do deep equality?
                                 # For now, keep it simple.
                                 # First: check keys match up exactly
                                 if (x.keys.length != y.keys.length)
                                   return MalFalse.new()
                                 end
                                 # Next: check each key points to same value
                                 x.keys.each { |k|
                                                  if !y.exists(k) ||
                                                     (MalCore::Env['='].call(x.get(k), y.get(k)).is_a?(MalFalse))
                                                    return MalFalse.new()
                                                  end
                                             }
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
    'throw'       => lambda { |e|
                                  raise MalThrownError.new(malexp: e), e.print(false)
                            },
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
    'nil?'        => lambda { |x| x.is_a?(MalNil) ? MalTrue.new() : MalFalse.new() },
    'true?'       => lambda { |x| x.is_a?(MalTrue) ? MalTrue.new() : MalFalse.new() },
    'false?'      => lambda { |x| x.is_a?(MalFalse) ? MalTrue.new() : MalFalse.new() },
    'symbol?'     => lambda { |x| x.is_a?(MalSymbol) ? MalTrue.new() : MalFalse.new() },
    'symbol'      => lambda { |x| MalSymbol.new(x.data) },
    'keyword'     => lambda { |x| MalKeyword.new(x.data) },
    'keyword?'    => lambda { |x| x.is_a?(MalKeyword) ? MalTrue.new() : MalFalse.new() },
    'vector'      => lambda { |*x|
                                   y = MalVector.new()
                                   x.each { |i| y.push(i) }
                                   return y
                            },
    'vector?'     => lambda { |x| x.is_a?(MalVector) ? MalTrue.new() : MalFalse.new() },
    'sequential?' => lambda { |x| (x.is_a?(MalVector) || x.is_a?(MalList)) ? MalTrue.new() : MalFalse.new() },
    'hash-map'    => lambda { |*x|
                                  if !x.length.even?
                                    raise MalBadHashMapError
                                  end
                                  y = MalHashMap.new()
                                  x.each { |i| y.push(i) }
                                  return y
                            },
    'map?'        => lambda { |x| x.is_a?(MalHashMap) ? MalTrue.new() : MalFalse.new() },
    'assoc'       => lambda { |h, *kv|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "first arg to 'assoc' must be hash"
                                  end
                                  if !kv.length.even?
                                    raise MalBadHashMapError
                                  end
                                  y = MalHashMap.new()
                                  h.keys.each { |k| y.set(k, h.get(k)) }
                                  kv.each { |i| y.push(i) }
                                  return y
                            },
    'dissoc'      => lambda { |h,*l|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "first arg to 'dissoc' must be hash"
                                  end
                                  y = MalHashMap.new()
                                  # FIXME There must be a more idiomatic way to do this
                                  # Map? We want all the keys in h not present in l.
                                  h.keys.each { |k|
                                                    add = true
                                                    l.each { |item|
                                                                if item.data == k.data
                                                                  add = false
                                                                  break
                                                                end
                                                           }
                                                    if add
                                                      y.set(k, h.get(k))
                                                    end
                                               }
                                  return y
                            },
    'get'         => lambda { |h,k|
                                  # Return nil if nil
                                  if h.is_a?(MalNil)
                                    return MalNil.new()
                                  end
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "first arg to 'get' must be hash"
                                  end
                                  return h.get(k)
                            },
    'contains?'   => lambda { |h,k|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "first arg to 'contains?' must be hash"
                                  end
                                  return h.exists(k)
                            },
    'keys'        => lambda { |h|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "arg to 'keys' must be hash"
                                  end
                                  y = MalList.new()
                                  h.keys.each { |k| y.push(k) && puts(k) } # NB h.keys and not h.data.keys
                                  puts "in keys returning:"
                                  pp y
                                  return y
                            },
    'vals'        => lambda { |h|
                                  if !h.is_a?(MalHashMap)
                                    raise MalBadHashMapError, "arg to 'vals' must be hash"
                                  end
                                  y = MalList.new()
                                  h.data.values.each { |k| y.push(k) } # NB h.data.values and not h.values
                                  return y
                            },
    'readline'    => lambda { |p|
                                 if !p.is_a?(MalString)
                                   raise MalBadPromptError
                                 end
                                 s = grabline(p.data) # readline.rb
                                 if s
                                   return MalString.new(s, false)
                                 else
                                   return MalNil.new()
                                 end
                            },
    'time-ms'     => lambda { |*x| (Time.new().to_f * 1000).to_i },
    'meta'        => lambda { |*x| raise MalNotImplementedError },
    'with-meta'   => lambda { |*x| raise MalNotImplementedError },
    'fn?'         => lambda { |*x| raise MalNotImplementedError },
    'string?'     => lambda { |*x| raise MalNotImplementedError },
    'number?'     => lambda { |*x| raise MalNotImplementedError },
    'seq'         => lambda { |*x| raise MalNotImplementedError },
    'conj'        => lambda { |*x| raise MalNotImplementedError },
    'macavity'    => lambda { |*x| raise MalNotImplementedError },
  }
  Mal = {
    'not' => '(def! not (fn* (a) (if a false true)))',
    'load-file' => '(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) "\nnil)")))))',
    'cond' => "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list \'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons \'cond (rest (rest xs)))))))"
  }
end
