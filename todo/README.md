# To-do list manager

An implementation of the program written in chapter 2, a simple CLI to manage todo
lists.

The implementation turned up pretty heavily functorized, in an effort to explore what
dependency injection can look like when implemented mostly via functors in OCaml. It's a
bit over-the-top for such a simple program, but it was nice to take this idea far and
see how much of the program are actually details that can be swapped away, such as the
persistence mechanism and the serialization format. The core of the program, the
management of the to-do lists themselves, remains simple and isolated from all those
details. This view also guided how tests were written and how the surface API of the
library portion ended up looking like.

For a while I had a hard time deciding where to put the boundary of what went on `lib`
and what to leave on `bin`. I wanted to keep `bin` small (because it can't be
unit-tested), but not too small that it forced the `lib`'s API to be too awkward to use
as a library.

The `Serializer` interface ended up having a somewhat awkward signature for the `load`
function; this attempted to achieve a compromise between making it general while making
it easy to use with the actual implementation based on `Yojson`, which can accept a
`lexbuf`, the most general input API I could find of all that `Yojson` provides. Using
`string` instead would have also worked fine for the most part, but wouldn't allow
buffered input (like reading from a file without loading the whole file at once). Note
that the original Go implementation in the book does not use buffered input here either.

The tests on `file_persistence.ml` are the kind of tests that can be on the brittle side
due to them mocking with a lot of detail. I think these are fine as long as one
understands accepts them for what they are and is ready to get rid of them or modify
them heavily if needed. The rest of the tests can work with a mocked out `Persistence`
module, which I think is the right approach for testing the behavior.

I wanted to make it so that it would be easy to simply provide modules from `Stdlib` to
the `File.Make_persistence` functor, because that would make it more straightforward to
use and test. Doing so while guaranteeing the behavior that I wanted ended up involving
three modules (`In_channel`, `Out_channel` and `Sys`), which I decided to wrap in a
single module to reduce the number of arguments. This sacrifices leaking implementation
details for convenience and unit test coverage.

I ignored the time-related aspects of tasks in the implementation, since the app that
the book ends up building doesn't really expose it for anything.
