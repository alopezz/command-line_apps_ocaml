# Word Counter

An implementation of the program written in chapter 1, which is a clone of the classic
`wc` utility.

I tried to stay reasonably faithful to how the actual implementation works in Go, in the
sense of using buffered IO instead of trying to get away with getting all the input at
once and processing it directly with string manipulation functions.

I ended up with something that works pretty similarly to how scanning with a `SplitFunc`
works in Go. This makes the code generic enough in that adding a new counter would be a
matter of providing a custom `split` function. I implemented a splitter that returns a
sequence of tokens to make it even closer to the use of Go's `Scan`. Then counting is
simply a matter of getting the length of the sequence (as the Go code does). I left this
as an internal implementation detail (not exposed by the module).

The main concept that I wanted to try out for this program, though, is the dependency
injection of the input channel via a functor, so that I could test the program from
strings without having to do any actual IO; this worked well and the string-based input
stub turned out simple enough. Using a single function to represent the input (as that's
all I ended up needing) could have been another reasonable alternative, but I like the
functor here as it doesn't really add that much boilerplate or complexity, allows for
future expansion of the interface (in case more functions are needed), and reduces the
need for passing the input function around everywhere (as much as one can mitigate with
partial application).
