Basic test for counting words (the default)
  $ echo "word1 word2 word3 word4" | wc
  4

Mixing space characters
  $ echo "word1          word2   word3
  > word4
  > word5 word6" | wc
  6

Counting bytes
  $ printf "Hello world" | wc -b
  11

Counting lines
  $ echo "first
  > second
  > and third line" | wc -l
  3
