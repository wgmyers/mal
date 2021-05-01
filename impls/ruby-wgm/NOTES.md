# Notes

## Step 0

This went fine, eventually.

The readline implementation is extremely simple and just uses the minimal
functionality from a single call to the Ruby readline library. I might want
to revisit that later on.

## Step 1

This too went fine, eventually: the guide text is I think deliberately vague
about exactly how to implement the reader, the whole thing being an exercise
for the reader and all that.

So. We are now passing all the symbols, numbers and lists tests.

We are not yet testing for and handling mismatched parens: this definitely needs
fixing.

We have also not yet implemented any kind of special type handling in types.rb,
but we will have to later on when we come to differentiating between lists and
vectors. We don't even have a types.rb yet - the whole data structure is, for
now, a simple Ruby array. I suspect this will not suffice for many more steps.

On the other hand, this is enough for now, which means we can either go ahead
and have a crack at Step 2, or have a go at implementing types.rb and having
our types be properly, uh, typed.

I think we need to do types now. Bah.
