# Notes

## Step 2

We have it working, but it's clunky and we have to manually convert from
Mal datatypes to Integer (and back) before doing anything. But it works,
including nested arithmetic.

Now passing all the step two tests.

Problems discovered: We only handle integers at the moment, as our parser
does not recognise decimal points. This is obviously rubbish and needs fixing.

## Step 1

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

## Step 0

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
