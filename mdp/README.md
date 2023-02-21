# Markdown Previewer (MDP)

I've cut some corners for this one:

- I didn't include HTML sanitization in this version.
- Only implemented logic to add the `rel="nofollow"` HTML attribute to enough elements
  to make the tests based on the examples pass.
- I was more lax on the testing:
  - I didn't add tests for error cases when reading and writing to files, even though I
    had everything in place (with the functor-based DI) to do so.
  - Didn't get into the rabbit holes of testing the file system wrapper nor the "open in
    browser" portions of the program.
- I'm obviously not supporting the whole Go templating language, just the bare minimum
  to make the examples work, which boils down to string substitution of the relevant
  placeholders.
