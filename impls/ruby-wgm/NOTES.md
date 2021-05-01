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

We have (finally) implemented a types.rb to handle types.
