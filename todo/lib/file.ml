module type File_system = sig
  module In : sig
    type t
    val with_open_text : string -> (t -> 'a) -> 'a
    val input : t -> bytes -> int -> int -> int
  end

  module Out : sig
    type t
    val with_open_text : string -> (t -> 'a) -> 'a
    val output_string : t -> string -> unit
  end

  module Sys : sig
    val file_exists : string -> bool
  end
end

module type Serializer = sig
  (** dump [todo_list] returns a serialization of [todo_list] *)
  val dump : Todo_list.t -> string

  (** load [input] deserializes the contents provided by the [input] function into a
     todo list *)
  val load : (bytes -> int -> int) -> (Todo_list.t, string) result
end

module Real_file_system = struct
  module In = In_channel
  module Out = Out_channel
  module Sys = Sys
end

(** A file-system based persistence. *)
module Make_persistence (S : Serializer) (Fs : File_system) : Cli.Persistence = struct
  let save filename todo_list =
    try
      Ok (Fs.Out.with_open_text filename
            (fun oc -> Fs.Out.output_string oc @@ S.dump todo_list))
    with
      Sys_error err -> Error err

  let load filename =
    if Fs.Sys.file_exists filename then
      match
        Fs.In.with_open_text filename
          (fun ic ->
             S.load (fun buf len -> Fs.In.input ic buf 0 len))
      with
      | Ok lst -> Ok (Some lst)
      | Error err -> Error err
      | exception Sys_error err | exception Invalid_argument err -> Error err
    else
      Ok None
end
