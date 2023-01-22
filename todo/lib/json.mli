val dump : Todo_list.t -> string

val load : (bytes -> int -> int) -> (Todo_list.t, string) result
