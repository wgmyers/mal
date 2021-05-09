# Notes

## Step 9 (2021-05-09)

Try/catch.

This would be a good step to go through and look at error handling more closely
all over and see too what extent we can a) catch our own exceptions instead of
leaving it to Ruby, and b) provide useful error messages.

Certainly, by this stage, I now have a deeper understanding of why error messages
are often not hugely useful. It is difficult to implement.

It would be good to have our DEBUG flags stored differently so we could toggle
them from within the REPL. This is probably a good step to implement that too.

Meanwhile I have read over the guide for the implementation of try/catch at
least five times and I am not at all sure how to do it. Time to reread.

## Step 8 (2021-05-08)

Macros.

MalFunction (tee hee) now has an is_macro attribute, and we also have a
defmacro! special form that checks if it is creating a function, and if so,
sets it to true.

is_macro_call and macroexpand now implemented, and wired into EVAL with a
call to macroexpand before the apply section and a 'macroexpand' special form.

Blow me. That worked first time. All remaining failing tests are deferrables.

Bit spooked, tbh.

Ok, then, time to implement nth, first and rest, and to add cond to the list
of Mal-implemented functions.

All done. Still two failing tests: first and rest aren't dealing with nil
properly.

And now they are, after some confusion where I forget that the nil they were
getting was not actually Ruby nil but MalNil.

So. All Step 8 tests now pass. Eep.

## Step 7 (2021-05-08)

Quote and quasiquote time.

This was mostly straightforward, though actually implementing the quote and
quasiquote stuff revealed numerous bugs in reader.rb, as the token expansion
code in expand_macros was not actually working properly after all and did not
handle nested macros in more than one set of brackets.

I'm pretty sure there'll be similar nesting problems in the with-meta macro
implementation, but we'll deal with those in Step A, should we get there.

The other issue I encountered was handling vectors in the quasiquote function.

It was all fine until I needed to implement selective non-handling of 'unquote',
which meant the recursive implementation would fail. I tried removing and then
replacing the 'unquote' symbol, but this led to lists being stripped of their
listness. Instead, I found another highly inelegant solution: when quasiquote
encounters 'unquote' as the first element of a vector, it changes it to
'hidden-unquote' before recursing, and then changes it back so it behaves.

Never mind. Step 8 time!

## Step 6 (2021-05-05)

Initial implementation of load-file mostly works.

We can successfully load a file and run it.

However, we print a spurious nil afterwards, which needs fixing.

Also, we get weird startup now, where parts of load-file are printed for no
obvious reason.

Initial implementation of atoms. Mostly works, lots of bugs and failing tests.

This test: (def! a (atom 2)) should return (atom 2). We don't have any other
similiar tests. I'm guessing we should behave like MalList does and manually
create a string like "(atom " + data.print() + ")"

Next problem: my implementation of swap takes one or more arguments, but we
want zero or more arguments. Ok, let's fix that.

Trickier than expected - swap needs to be able to take either a MalFunction
or a built in, which have different calling semantics, but, anyway, fixed.

Now passing all non-optional / deferrable tests. Time to implement that.

First up - we have never been handling comments properly. Time to fix that.
IIUC, a lisp comment is anything following a ';' to the end of that line.
Comments may be prefixed with one or more semicolons according to convention,
but we don't need to worry about that - as soon as we see a symbol beginning
with ';' (so ";" is ok and not a comment) our reader needs to stop parsing
everything until it sees \n. So back to reader.rb we go.

Aaand... that was surprisingly straightforward, as the given regex is already
munging everything after a ';' into a single token, so we just need to zip
through the token list and throw away anything beginning with ';'.

All that is left is to implement *ARGV* and taking files from the command line.

This is trickier than it seems - in order to pass the tests we need to fix the
spurious output from parsing the definition of load-file and also stop load-file
from outputting the filename given to it. Might be nice to lose the trailing
'nil' as well. Meanwhile I'm not sure why any of that is happening.

Right. Spurious string printing solved by removing debug code from MalString
in types.rb that I had forgotten about. This is why you aren't supposed to
do that kind of debugging. Bah.

Also, the inputs from (Ruby) ARGV need to be unfrozen strings. Ok then.

All that remains is to track down and remove the spurious trailing nil.

It... seems to be coming from within load-file itself?

If we enter nil at the prompt, we are supposed to return nil. Except when it's
load-file. If I have understood correctly. That... can't be right?

So.. we just print the output of command line loading with [0...-4] to suppress
the "\nnil" that we added. That's... fine. We now pass all Step 4 test including
regressions.

I'm still not sure we are handling strings / eval right.

The following returns the string rather than evalling:

```
user> (eval "(do (prn \"poop\"))\nnil")
"(do (prn \"poop\"))\nnil"
```

The following is even more horrible:

```
user> (def! prog (str "(do (prn \"poop\")"))
"(do (prn \"poop\")"
user> prog
"(do (prn \\\"poop\\\")"
user> (eval prog)
"(do (prn \\\\\\\"poop\\\\\\\")"
user> prog
"(do (prn \\\\\\\\\\\\\\\"poop\\\\\\\\\\\\\\\")"
user> prog
"(do (prn \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"poop\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\")"
```

I *must* still be doing something wrong. But I've not trusted my string handling
from the very beginning, and meanwhile, Step 7 beckons.

Hang on though. This fails. We aren't done yet.

```
(def! mal-prog (list + 1 2))
(eval mal-prog)
```

Actually, `(list + 1 2)` fails, because it tries to print + which is somehow now
a Proc and not a MalSymbol or MalString. Er, eh? Do we need to wrap our core
functions in another MalType? That might fix it.

Oh crap I've been handling the whole Env object wrong. Items are keyed on
strings and not MalSymbols, which means we're fine until we have two symbols
in a row where we want one to evaluate to the lambda and one to stay as it is.
But so what? Even if we do refactor the whole thing, the default evaller is
still calling eval_ast on the list here, and that is still going to merrily
look up both 'list' and '+' however we store them.

We can't fix this in the lambda as it is too late.

I can't find another example in the tests where 'list' is followed by another
MalSymbol.

Time for a brutal hack in the default evaller, just for 'list', where if the
first item in a list is 'list' we pass the second item through unchanged if
it happens to be a MalSymbol (otherwise we eval_ast it along with the rest, as
normal).

I am not at all sure about this, obviously.

I've done it though.

I think the root cause maybe that I have an over-simple implementation of my
Env object: a more elegant solution might be to be able to look up the associated
symbol for a given proc and then return that if we are unexpectedly asked to
print it. Lets see if anything else triggers this kind of behaviour. Maybe it
won't? On the other hand... wait, we are about to implement quote, which is a
mechanism for deliberately marking symbols as 'do not eval me'.

A more elegant, or at least less unelegant solution would be to allow builtins
to get replaced by Proc in the EVAL process and just deal with them. But a quick
crack at doing this reveals that the problem involves more than just fixing the
print method of MalList - the EVAL loop itself assumes the first item in the
loop will have a @data attribute. So will leave this here for now and move on.

I bet future steps force us to revisit this anyway.

Anyway, on to Step 7.

## Step 5 (2021-05-04)

Ok, we've made EVAL always loop.

Next, we modify the following:

* let* - done.
* do   - done. Worried about this one as we modified it before :(
* if   - done
* fn*  - done
* default 'apply' - done

Run some tests from elsewhere to make sure things haven't broken. Test coverage
on this one is less comprehensive than others.

Nearly there, except the Redefine def! test fails. Hiliarious. We didn't
modify it. Hah. Ok, why is that happening?

Added a DEBUG constant to hold debug flags.

Added 'q' for quit so I stop typing 'Ctrl-D' in the terminal and closing it.

(Much failed debugging later...)

I'm stumped for now. Need to automate the running of a bunch of tests so I can
see more easily what is going on. Items created by def! aren't persisting, which
is definitely to do with some of it. The new MalFunction originally didn't have
a value called data, which may also be related, as everything else does and
there is foo.data liberally in the code. The fib function from Step 4 blows up
with a stack too deep error, which makes me think that something somewhere is
pointing to itself, but the root cause of all of this is probably the way the
env thing is stored and manipulated - EVAL is still returning env rather than
changing a (global?) env stored elsewhere. Maybe I should fix that?

Also it is not clear what env.set should return - currently it returns self,
but again, this might have worked before but not now.

So that's where we're at.

Maybe I should take a short break and learn graphviz. This is getting hairy.
See https://twitter.com/thingskatedid/status/1386077306381242371

So, I tried it. EVAL no longer returns env - and lo all the Step 5 tests pass!

But, I just discovered the regression tests, and we are now failing some of
the Step 4 tests.

make REGRESS=1 "test^ruby-wgm^step5" is my new friend.

The Step 4 tests that were failing were all in 'do'.

The fix was to call EVAL on each element of the list and not eval_ast, just
as before. I am now wondering if I did something wrong in eval_ast such that
it breaks do (but being called via EVAL is ok). Presumably we'll find out at
a later stage. For now, though, on to Step 6!

## Step 4 (2021-05-03)

This is easily the trickiest bit yet.

We have Environments taking binds and expression on instantiation and calling
'set' on them if they appear to match in length.

Support for printing values of functions nominally added, not in printer.rb,
but in types.rb, where we now have a nominal MalFunction (teehee) type. I'm
not sure how this will fit in in future, but looks like Step 5 demands a type
for functions anyway? Unless I've misunderstood. It's possible.

Keyword 'do' implemented. Guide says to call eval_ast, but this didn't work
straightaway: eval_ast doesn't handle the special keywords, so something
like (do (def! a 1) (+ 1 a)) failed. Calling EVAL instead worked.

Keyword 'if' implemented. Very straightforward, especially after 'do'.

Keyword 'fn*' partially implemented, but with bugs, and also showing up bugs
in def!, with which it should, but does not yet play nicely.

Running tests absolutely blows up on the attempt to calculate Fibonacci numbers.

But let's go ahead and implement the rest of Step 4, then go back and debug fn*.

Ok, done, mostly.

Fixed the infinite loop bug and have no idea how.

All fn* tests now passing, anyway.

I thought it was because def! was returning item,env and not nil,env, so
anything using def and recursion was bugging out. But that means def! returns
the wrong thing now, and having fixed further bugs from other tests, restoring
a return of item,env does not after all trigger an infinite loop.

Remaining non-optional bug is that def! fn*s don't nest properly?

Implemented not in Mal. Cute.

Implemented extra string functions. All the tests pass apart from string bugs
not caught by previous tests (looking at you, "\\n")

Attempted to add variadic bindings with '&'. Total failure. I think it's b/c
we are splatting all our arguments anyway when we create the closure in order
to create it without using eval. I wonder if we can fix it in the closure
instead of in the Env bindings.

Fixed list/vector comparison bugs: Mal wants to treat lists and vectors as the
same for comparison (this is not intuitive but then I don't know Lisp), so now
we have a recursive lambda for '=' that calls itself if it finds data which is
either MalList or MalVector.

Fixed nested def! fn* flagged by tests. This was hard to fix because it was
not in fact a bug caused by nested functions, which work fine. It was a bug in
the reader, which was reading any symbol ending in \d as a MalNumber, and the
test was calling the functions things like gen-plus5. Now fixed.

Fixed "\\n" bug. All string tests now pass, though we still have not eliminated
all string bugs, as things like """"" are still accepted quite happily.

Finally fixed the variadic bindings issue. Actually the code was fine, it just
wasn't actually doing what I intended. Poking at it and fixing the thinkos made
everything just work.

So, all Step 4 tests now pass.

## Step 3 (2021-05-02)

With some pain, def! is now implemented.

This has involved altering EVAL to return the environment on each call,
rather than using a global variable for it. Otherwise, changes to the
environment made in EVAL do not persist for future invocations.

I am not at all sure about this: it is not what the pseudo-code says to do.
That says we need to use a global. I guess we'll see. Scanning forward, it
looks like we'll be ok until implementing TCO in Step 5, which looks super-hairy
so at that point, either we revert to a global (or some cleaner but equivalent
alternative if I can dream one up) or it turns out that we were fine all along.

Anyway. Now to implement let*.

Er, that wasn't too painful at all.

We still have issues with not being sure when things are Mal objects or not,
but all Step 3 tests now pass, so on to Step 4.

## Step 2 (2021-05-02)

We have it working, but it's clunky and we have to manually convert from
Mal datatypes to Integer (and back) before doing anything. But it works,
including nested arithmetic.

Now passing all the step two tests.

Problems discovered: We only handle integers at the moment, as our parser
does not recognise decimal points. This is obviously rubbish and needs fixing.

## Step 1 (2021-05-02)

This too went fine, eventually: the guide text is I think deliberately vague
about exactly how to implement the reader, the whole thing being an exercise
for the reader and all that.

So. We are now passing all the symbols, numbers and lists tests.

We have (finally) implemented a types.rb to handle types.

We have implemented vectors

We have partially implemented hashmaps and mismatched parens finding. Some
errors remain with mismatches and hashmaps accept anything as keys, which
is wrong.

We have partially implemented strings and keywords.

We have implemented all reader macros.

We appear to have partially implemented comments for free in the tokeniser,
but we don't yet handle 'everything is a comment' properly.

We are now passing all Step 1 tests.

## Step 0 (2021-05-01)

This went fine, eventually.

The readline implementation is extremely simple and just uses the minimal
functionality from a single call to the Ruby readline library. I might want
to revisit that later on.

## TODO

* FIXED (Step 5) Entering nothing in the REPL yields an error. Fix this.
* Implement float handling. Ints only for now.
* Implement hashmaps properly (only strings or keywords as keys)
* FIXED (Step 6) Implement comments properly
* Check we are truly handling strings properly (seems doubtful)
* Improve readline implementation.

## SNIPPETS

* Reverse a list:

(def! rev (fn* (xs) (if (= (count xs) 1) xs (concat (rev (rest xs)) (list (first xs))))))

Can't seem to make that work with defmacro! though. I don't know if it's bugs
in my implementation or my near-complete ignorance of how Lisp works.
