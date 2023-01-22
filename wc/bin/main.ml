module Wc_in = Wc.Make(In_channel)

let () =
  let by_bytes = ref false in
  let by_lines = ref false in
  let speclist =
    [
      ("-b", Arg.Set by_bytes, "Count bytes");
      ("-l", Arg.Set by_lines, "Count lines");
    ]
  in
  Arg.parse speclist (fun _ -> ()) "Word counter";
  let count =
    match (!by_bytes, !by_lines) with
    | true, _ -> Wc_in.count_bytes
    | false, true -> Wc_in.count_lines
    | false, false -> Wc_in.count_words
  in
  count stdin |> print_int;
  print_newline ();
