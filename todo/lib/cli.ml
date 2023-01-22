module type Printer = sig
  val print : string -> unit
end

module type Persistence = sig
  (** save [name] [todo_list] stores [todo_list] under [name] *)
  val save : string -> Todo_list.t -> (unit, string) result

  (** load [name] returns the todo list stored under [name]
      A [None] value is returned when no todo list exists for the
      given [name]. *)
  val load : string -> (Todo_list.t option, string) result
end

module Make (Printer : Printer) (Persistence : Persistence) : sig
  val add : string -> string -> unit
  val add_bulk : string -> string list -> unit
  val list : string -> unit
  val complete : string -> int -> unit
  val delete : string -> int -> unit
end = struct
  let (>>=) = Result.bind
  let (>>|) a b = Result.map b a

  let fallback = Option.value ~default:Todo_list.empty

  let load name =
    Persistence.load name
    >>| fallback
    |> Result.map_error (Printf.sprintf "Loading error: %s\n")

  let save name lst =
    Persistence.save name lst
    |> Result.map_error (Printf.sprintf "Saving error: %s\n")

  (** Loads the list from file, modifies it with the given function, and saves it *)
  let with_todo_list name edit =
    load name
    >>| edit
    >>= save name
    |> Result.iter_error Printer.print

  let add name task_name =
    with_todo_list name (Todo_list.add_task task_name)

  let add_bulk name task_names =
    let reduce f = Fun.flip (List.fold_left (Fun.flip f)) in
    with_todo_list name
      (reduce Todo_list.add_task task_names)

  let render_task idx task =
    let mark = if task.Todo_list.done_ then "X" else " " in
    Printf.sprintf "[%s] %d: %s\n" mark (idx + 1) task.Todo_list.task

  let render_task_list lst =
    Todo_list.to_list lst
    |> List.mapi render_task
    |> String.concat ""

  let list name =
    load name
    >>| render_task_list
    |> (function | Ok v | Error v -> Printer.print v)

  let complete name idx =
    with_todo_list name (Todo_list.complete idx)

  let delete name idx =
    with_todo_list name (Todo_list.delete idx)
end
