# Notes

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
* Implement comments properly
* Check we are truly handling strings properly (seems doubtful)
* Improve readline implementation.
