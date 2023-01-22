type t

(** Type representing a task *)
type task = { task : string; done_ : bool }

(** Returns the list of tasks in [lst] in order of addition *)
val to_list : t -> task list

(** Builds a list of tasks from given [lst] *)
val of_list : task list -> t

(** An empty todo list *)
val empty : t

(** Adds a task named [task_name] to the list *)
val add_task : string -> t -> t

(** Marks task number [idx] as done *)
val complete : int -> t -> t

(** Deletes task number [idx] from the list *)
val delete : int -> t -> t


(** Saves todo list to a JSON file *)
(* val save : string -> Task.task list -> unit *)

(* (\** Loads a todo list from a JSON file *\) *)
(* val load : string -> (Task.task list, string) result *)
