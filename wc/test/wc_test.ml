(* A module that simulates input from a string *)
module String_in = struct
  type t = { contents : string; mutable idx : int }

  let input ({ contents; idx } as in_channel) buf pos len =
    (* Cap bytes read according to what's actually left on the string *)
    let actual_len = Int.min len (String.length contents - idx) in
    Bytes.blit_string contents idx buf pos actual_len;
    in_channel.idx <- idx + actual_len;
    actual_len

  let make contents = { contents; idx = 0 }
end

module String_wc = Wc.Make (String_in)

let word_tests =
  let make_test case_name input expected =
    Alcotest.test_case case_name `Quick (fun () ->
        Alcotest.(check @@ int)
          (Printf.sprintf "Result is %d" expected)
          expected
        @@ String_wc.count_words (String_in.make input))
  in
  [
    make_test "An empty string" "" 0;
    make_test "A single word" "word" 1;
    make_test "Two words separated by a single space" "hello world" 2;
    make_test "Two words separated by multiple consecutive spaces" "hello   world" 2;
    make_test "Spaces before and after any words" "  count these words     " 3;
    make_test "Combination of different spacers"
      "first line
       second\tline\tuses\ttabs\ttoo"
      7;
    make_test "Larger input"
      "One two three four five six seven eight nine ten
       one two three four five six seven eight nine ten
       one two three four five six seven eight nine ten
       one two three four five six seven eight nine ten
       one two three four five six seven eight nine ten
       one two three four five six seven eight nine ten
       one two three four five six seven eight nine ten
       one two three four five six seven eight nine ten
       one two three four five six seven eight nine ten
       one two three four five six seven eight nine ten"
      100;
  ]

let byte_tests =
  let make_test case_name input expected =
    Alcotest.test_case case_name `Quick (fun () ->
        Alcotest.(check @@ int)
          (Printf.sprintf "Result is %d" expected)
          expected
        @@ String_wc.count_bytes (String_in.make input))
  in
  [
    make_test "An empty string" "" 0;
    make_test "A short string" "foobar" 6;
    make_test "A longer string"
      (
        Seq.repeat "0123456789"
        |> Seq.take 200
        |> List.of_seq
        |> String.concat ""
      )
    2000;
  ]

let line_tests =
  let make_test case_name input expected =
    Alcotest.test_case case_name `Quick (fun () ->
        Alcotest.(check @@ int)
          (Printf.sprintf "Result is %d" expected)
          expected
        @@ String_wc.count_lines (String_in.make input))
  in
  [
    make_test "An empty string" "" 0;
    make_test "A single line" "this is a line" 1;
    make_test "Several lines"
      "first line
       second line
       third line"
      3;
    make_test "Empty lines also count"
      "first

       second"
      3;
    make_test "Other types of line breaks"
      "hello\r\nworld"
      2;
  ]


let () =
  Alcotest.run "wc"
    [
      ("Test counting words", word_tests);
      ("Test counting bytes", byte_tests);
      ("Test counting lines", line_tests);
    ]
