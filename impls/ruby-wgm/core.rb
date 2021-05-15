# frozen_string_literal: true

# core.rb

# Define our core functions here
module MalCore
  Env = {
    '+'           => lambda { |x, y| MalNumber.new(x.data + y.data) },
    '-'           => lambda { |x, y| MalNumber.new(x.data - y.data) },
    '*'           => lambda { |x, y| MalNumber.new(x.data * y.data) },
    '/'           => lambda { |x, y| MalNumber.new(x.data / y.data) }, # NB Divide by zero caught by Ruby, not us
    'prn'         => lambda { |*x| strs = x.map { |s| pr_str(s, readably: true) }
                                   puts(strs.join(' '))
                                   return MalNil.new # NB - return nil instead to suppress 'nil' print
                     },
    'println'     => lambda { |*x| strs = x.map { |s| pr_str(s, readably: false) }
                                   puts(strs.join(' '))
                                   return MalNil.new # NB - same as above.
                     },
    'pr-str'      => lambda { |*x| strs = x.map { |s| pr_str(s, readably: true) }
                                   return(MalString.new(strs.join(' '), sanitise: false))
                     },
    'str'         => lambda { |*x| strs = x.map { |s| pr_str(s, readably: false) }
                                   return(MalString.new(strs.join(''), sanitise: false))
                     },
    'list'        => lambda { |*x| l = MalList.new
                                   x.each { |i| l.push(i) }
                                   return l
                     },
    'list?'       => lambda { |x| x.instance_of?(MalList) ? MalTrue.new : MalFalse.new },
    'empty?'      => lambda { |x| x.data.length.zero? ? MalTrue.new : MalFalse.new },
    'count'       => lambda { |x| x.is_a?(MalNil) ? 0 : x.data.length },
    '='           => lambda { |x, y| if (x.instance_of?(MalList) || x.instance_of?(MalVector)) &&
                                        (y.instance_of?(MalList) || y.instance_of?(MalVector))
                                       return MalFalse.new unless x.length == y.length

                                       x.data.each_with_index { |item, idx|
                                         if item.is_a?(MalList)
                                           return MalFalse.new unless MalCore::Env['='].call(item, y.data[idx])
                                         else
                                           return MalFalse.new if item.data != y.data[idx].data
                                         end
                                       }
                                     elsif x.class != y.class
                                       return MalFalse.new
                                     elsif x.is_a?(MalHashMap)
                                       # QUERY - Shouldn't we try to do deep equality?
                                       # For now, keep it simple.
                                       # First: check keys match up exactly
                                       return MalFalse.new if x.keys.length != y.keys.length

                                       # Next: check each key points to same value
                                       x.keys.each { |k| if !y.exists(k) ||
                                                            MalCore::Env['='].call(x.get(k), y.get(k)).is_a?(MalFalse)
                                                           return MalFalse.new
                                                         end
                                                   }
                                     elsif x.data != y.data
                                       return MalFalse.new
                                     end
                                     return MalTrue.new
                     },
    '<'           => lambda { |x, y| x.data < y.data ? MalTrue.new : MalFalse.new },
    '<='          => lambda { |x, y| x.data <= y.data ? MalTrue.new : MalFalse.new },
    '>'           => lambda { |x, y| x.data > y.data ? MalTrue.new : MalFalse.new },
    '>='          => lambda { |x, y| x.data >= y.data ? MalTrue.new : MalFalse.new },
    'read-string' => lambda { |x| return read_str(x.print(readably: false)) },
    'slurp'       => lambda { |x| return MalString.new(File.read(x.print(readably: false)), sanitise: false) }, # FIXME: Error checking?
    'atom'        => lambda { |x| return MalAtom.new(x) },
    'atom?'       => lambda { |x| return x.is_a?(MalAtom) },
    'deref'       => lambda { |x| return x.deref },
    'reset!'      => lambda { |x, y| return x.reset(y) },
    'swap!'       => lambda { |x, *y| return x.swap(y) },
    'cons'        => lambda { |x, y| z = MalList.new
                                     z.push(x)
                                     y.data.each { |i| z.push(i) }
                                     return z
                     }, # FIXME: Error checking?
    'concat'      => lambda { |*x| y = MalList.new
                                   x.each do |l|
                                     l.data.each { |i| y.push(i) }
                                   end
                                   return y
                     }, # FIXME: Error checking? What if not list?
    'vec'         => lambda { |x| return x if x.is_a?(MalVector)

                                  y = MalVector.new
                                  x.data.each { |i| y.push(i) }
                                  return y
                     }, # FIXME: Error checking? What if not list or vector?
    'nth'         => lambda { |x, y| raise MalIndexOutOfRangeError if y.data >= x.data.length

                                     return x.data[y.data]
                     }, # FIXME: Error checking? What if not list or vector?
    'first'       => lambda { |x| (!x.is_a?(MalNil) && x.data.length.positive?) ? x.data[0] : MalNil.new },
    'rest'        => lambda { |x| y = MalList.new
                                  return y unless !x.is_a?(MalNil) # back out now if x is nil

                                  x.data.drop(1).each { |i| y.push(i) }
                                  return y
                     },
    'throw'       => lambda { |e| raise MalThrownError.new(malexp: e), e.print(readably: false) },
    'apply'       => lambda { |f, *ins| if !(f.is_a?(MalFunction) || f.is_a?(Proc)) ||
                                           !(ins[-1].is_a?(MalList) || ins[-1].is_a?(MalVector))
                                          raise MalBadApplyError
                                        end

                                        argsl = ins[-1]
                                        ins.reverse.each { |i| argsl.data.unshift(i) unless i == argsl }
                                        return f.call(*argsl.data) if f.is_a?(Proc) # handle builtins

                                        return f.call(argsl.data)
                     },
    'map'         => lambda { |f, ins| raise MalBadMapError, 'first arg to map must be function or builtin' unless f.is_a?(MalFunction) || f.is_a?(Proc)
                                       raise MalBadMapError, 'second arg to map must be list or vector' unless ins.is_a?(MalList) || ins.is_a?(MalVector)

                                       y = MalList.new
                                       ins.data.each { |i| f.is_a?(Proc) ? y.push(f.call(*i)) : y.push(f.call(i)) }
                                       return y
                     },
    'nil?'        => lambda { |x| x.is_a?(MalNil) ? MalTrue.new : MalFalse.new },
    'true?'       => lambda { |x| x.is_a?(MalTrue) ? MalTrue.new : MalFalse.new },
    'false?'      => lambda { |x| x.is_a?(MalFalse) ? MalTrue.new : MalFalse.new },
    'symbol?'     => lambda { |x| x.is_a?(MalSymbol) ? MalTrue.new : MalFalse.new },
    'symbol'      => lambda { |x| MalSymbol.new(x.data) },
    'keyword'     => lambda { |x| MalKeyword.new(x.data) },
    'keyword?'    => lambda { |x| x.is_a?(MalKeyword) ? MalTrue.new : MalFalse.new },
    'vector'      => lambda { |*x| y = MalVector.new
                                   x.each { |i| y.push(i) }
                                   return y
                     },
    'vector?'     => lambda { |x| x.is_a?(MalVector) ? MalTrue.new : MalFalse.new },
    'sequential?' => lambda { |x| (x.is_a?(MalVector) || x.is_a?(MalList)) ? MalTrue.new : MalFalse.new },
    'hash-map'    => lambda { |*x| raise MalBadHashMapError unless x.length.even?

                                   y = MalHashMap.new
                                   x.each { |i| y.push(i) }
                                   return y
                     },
    'map?'        => lambda { |x| x.is_a?(MalHashMap) ? MalTrue.new : MalFalse.new },
    'assoc'       => lambda { |h, *kv| raise MalBadHashMapError, "first arg to 'assoc' must be hash" unless h.is_a?(MalHashMap)
                                       raise MalBadHashMapError unless kv.length.even?

                                       y = MalHashMap.new
                                       h.keys.each { |k| y.set(k, h.get(k)) }
                                       kv.each { |i| y.push(i) }
                                       return y
                     },
    'dissoc'      => lambda { |h, *l| raise MalBadHashMapError, "first arg to 'dissoc' must be hash" unless h.is_a?(MalHashMap)

                                      y = MalHashMap.new
                                      # FIXME: There must be a more idiomatic way to do this
                                      # Map? We want all the keys in h not present in l.
                                      h.keys.each do |k| add = true
                                                         l.each do |item| if item.data == k.data
                                                                            add = false
                                                                            break
                                                                          end
                                                                end
                                                         y.set(k, h.get(k)) if add
                                                   end
                                      return y
                     },
    'get'         => lambda { |h, k| return MalNil.new if h.is_a?(MalNil)
                                     raise MalBadHashMapError, "first arg to 'get' must be hash" unless h.is_a?(MalHashMap)

                                     return h.get(k)
                     },
    'contains?'   => lambda { |h, k| raise MalBadHashMapError, "first arg to 'contains?' must be hash" unless h.is_a?(MalHashMap)

                                     return h.exists(k)
                     },
    'keys'        => lambda { |h| raise MalBadHashMapError, "arg to 'keys' must be hash" unless h.is_a?(MalHashMap)

                                  y = MalList.new
                                  h.keys.each { |k| y.push(k) } # NB h.keys and not h.data.keys
                                  return y
                     },
    'vals'        => lambda { |h| raise MalBadHashMapError, "arg to 'vals' must be hash" unless h.is_a?(MalHashMap)

                                  y = MalList.new
                                  h.data.values.each { |k| y.push(k) } # NB h.data.values and not h.values
                                  return y
                     },
    'readline'    => lambda { |p| raise MalBadPromptError unless p.is_a?(MalString)

                                  s = grabline(p.data) # readline.rb
                                  return MalNil.new unless s

                                  return MalString.new(s, sanitise: false)
                     },
    'time-ms'     => lambda { |*x| (Time.new.to_f * 1000).to_i },
    'meta'        => lambda { |x| if x.is_a?(MalFunction) ||
                                     x.is_a?(MalList) ||
                                     x.is_a?(MalVector) ||
                                     x.is_a?(MalHashMap)
                                    return x.metadata
                                  end
                                  # meta on builtins returns nil
                                  return MalNil.new if x.is_a?(Proc)

                                  raise MalMetaError
                     },
    'with-meta'   => lambda { |x, y| unless x.is_a?(MalFunction) ||
                                            x.is_a?(MalList) ||
                                            x.is_a?(MalVector) ||
                                            x.is_a?(MalHashMap) ||
                                            x.is_a?(Proc)
                                       raise MalMetaError
                                     end

                                     # FIXME: Not at all sure this is how to handle the
                                     # case where with-meta gets a built-in.
                                     # For now, create a dummy function with empty ast, empty params,
                                     # nil environment and the given Proc as the closure.
                                     if x.is_a?(Proc)
                                       newx = MalFunction.new(MalList.new, MalList.new, MalNil.new, x)
                                       newx.metadata = y
                                       return newx
                                     end
                                     # Duplicate our result before returning it
                                     newx = x.dup
                                     newx.metadata = y
                                     return newx
                     },
    'fn?'         => lambda { |x| ((x.is_a?(MalFunction) && !x.is_macro) || x.is_a?(Proc)) ? MalTrue.new : MalFalse.new },
    'string?'     => lambda { |x| x.is_a?(MalString) ? MalTrue.new : MalFalse.new },
    'number?'     => lambda { |x| x.is_a?(MalNumber) ? MalTrue.new : MalFalse.new },
    'macro?'      => lambda { |x| x.is_a?(MalFunction) ? x.is_macro : MalFalse.new },
    'seq'         => lambda { |x| unless x.is_a?(MalString) ||
                                         x.is_a?(MalList) ||
                                         x.is_a?(MalVector) ||
                                         x.is_a?(MalNil)
                                    raise MalSeqError
                                  end
                                  if x.is_a?(MalNil) ||
                                     (x.is_a?(MalString) && x.data == '') ||
                                     (x.is_a?(MalList) && x.length.zero?) ||
                                     (x.is_a?(MalVector) && x.length.zero?)
                                    return MalNil.new
                                  end

                                  retval = x
                                  case x
                                  when MalVector # Convert vector to list
                                    retval = MalList.new
                                    x.data.each { |i| retval.push(i) }
                                  when MalString # Convert string to list of single char strings
                                    retval = MalList.new
                                    chars = x.data.split('')
                                    chars.each { |c| retval.push(MalString.new(c, sanitise: false)) }
                                  end
                                  return retval # NB MalList input is returned unchanged
                     },
    'conj'        => lambda { |col, *l| case col
                                        when MalVector
                                          ret = MalVector.new
                                          col.data.each { |i| ret.push(i) }
                                          l.each { |i| ret.push(i) }
                                        when MalList
                                          ret = MalList.new
                                          l.reverse.each { |i| ret.push(i) }
                                          col.data.each { |i| ret.push(i) }
                                        else
                                          raise MalConjError
                                        end
                                        return ret
                     },
    'ruby-eval'   => lambda { |x| raise MalEvalError, 'arg to ruby-eval must be string' unless x.is_a?(MalString)

                                  evil = Evaller.new(x.data)
                                  evil.do_eval
                                  return evil.ret
                     },
    'macavity'    => lambda { |*x| raise MalNotImplementedError }
  }.freeze

  Mal = {
    'not'       => '(def! not (fn* (a) (if a false true)))',
    'load-file' => '(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) "\nnil)")))))',
    'cond'      => "(defmacro! cond (fn* (& xs)
                       (if (> (count xs) 0)
                         (list \'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\"))
                         (cons \'cond (rest (rest xs)))))))"
  }.freeze

  # Evaller
  # A class to handle calls to Ruby eval
  # and the recursive conversion of their result to Mal types
  class Evaller
    attr_reader :str, :ret

    def initialize(str)
      @str = str
      @ret = nil
    end

    def do_eval
      begin
        rubyval = eval(str)
      rescue => e
        raise MalEvalError, e.message
      end
      @ret = ruby2mal(rubyval)
    end

    def ruby2mal(rubyval)
      case rubyval.class.to_s
      when 'String'
        MalString.new(rubyval, sanitise: false)
      when 'Integer'
        MalNumber.new(rubyval)
      when 'Array'
        arr = MalList.new
        rubyval.each { |i| arr.push(ruby2mal(i)) }
        arr
      when 'Hash'
        hash = MalHashMap.new
        rubyval.each_key { |k| hash.set(ruby2mal(k), ruby2mal(rubyval[k])) }
        hash
      else
        raise MalEvalError, "could not convert #{rubyval.class} to Mal type"
      end
    end
  end
end
