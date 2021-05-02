# Notes

## Step 4

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

* Implement float handling. Ints only for now.
* Implement hashmaps properly (only strings or keywords as keys)
* Implement comments properly
* Check we are truly handling strings properly (seems doubtful)
* Improve readline implementation.
