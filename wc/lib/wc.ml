module type Channel = sig
  type t
  val input : t -> bytes -> int -> int -> int
end

let split_words s = Str.split_delim (Str.regexp "[\t\r\n ]") s |> List.filter (fun s -> String.length s > 0)
let split_bytes = Str.split (Str.regexp "")
let split_lines = Str.split (Str.regexp "\\(\r\n\\|\n\\)")


module MakeSplitter (M : Channel) = struct
  let buffer_size = 1024

  (** Create a sequence of tokens from buffered input by applying [splitter] *)
  let split splitter ic =
    let buf = Bytes.create buffer_size in

    let rec next tokens =
      match tokens with
      | [prev] -> 
         let len = M.input ic buf 0 buffer_size in
         let split_str =
           prev ^ (Bytes.sub buf 0 len |> Bytes.to_string)
           |> splitter
         in
         (match split_str with
         | [] -> None
         | [last] when len = 0 -> Some (last, [])
         | tokens -> next tokens)
      | [] -> None
      | hd :: tl -> Some (hd, tl)
    in
    Seq.unfold next [""]
end

module Make (M : Channel) = struct
  module Splitter = MakeSplitter(M)

  let count splitter ic =
    Splitter.split splitter ic
    |> Seq.length

  let count_words = count split_words
  let count_bytes = count split_bytes
  let count_lines = count split_lines
end
