type task = { task : string; done_ : bool }

type t = task list

(* This pair of functions provides a level of abstraction in case we
   want to change the implementation of the Todo list, requiring
   to convert to and from a list at the boundary.
   Note that internally we are storing the tasks in reverse order.
 *)
let to_list lst = List.rev lst
let of_list lst = List.rev lst

let empty = []
let add_task task_name lst = { task = task_name; done_ = false } :: lst

let complete idx lst =
  let len = List.length lst in
  List.mapi
    (fun i t -> if len - i = idx then { t with done_ = true } else t)
    lst

let delete idx lst =
  let len = List.length lst in
  List.filteri (fun i _t -> len - i <> idx) lst
