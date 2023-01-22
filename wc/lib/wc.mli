(** A [Channel] represents an entity we can request input from. It's intended to be
   compatible with the standard library's [In_channel] module. *)
module type Channel = sig
  type t
  val input : t -> bytes -> int -> int -> int
end

module Make :
functor (M : Channel) ->
sig
  val count : (string -> string list) -> M.t -> int
  (** [count split channel] counts items from the channel as split by [split] *)

  val count_words : M.t -> int
  (** [count_words channel] counts words from the channel *)

  val count_bytes : M.t -> int
  (** [count_bytes channel] counts bytes from the channel *)

  val count_lines : M.t -> int
  (** [count_lines channel] counts lines from the channel *)
end
