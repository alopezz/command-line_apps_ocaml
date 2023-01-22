module File_persistence = Todo.File.Make_persistence (Todo.Json) (Todo.File.Real_file_system)

module Real_printer = struct let print = print_string end

module CLI = Todo.Cli.Make (Real_printer) (File_persistence)

let add_task_from_stdin filename =
  In_channel.input_all stdin |> String.split_on_char '\n'
  |> List.map String.trim
  |> List.filter (fun s -> String.length s > 0)
  |> CLI.add_bulk filename

let help_message =
  "todo [-add] [-list] [-complete] [-del]\n\n\
   A todo-list management utility.\n\
   Tasks can be added via an argument or via STDIN when using the -add flag.\n"

let () =
  let task_arg = ref "" in
  let add_flag = ref false in
  let list_flag = ref false in
  let complete_arg = ref 0 in
  let delete_arg = ref 0 in

  let arg_spec =
    [
      ( "-add",
        Arg.Rest_all
          (fun words ->
            add_flag := true;
            task_arg := String.concat " " words),
        "Add a new task" );
      ("-list", Arg.Set list_flag, "Print list");
      ("-complete", Arg.Set_int complete_arg, "Mark a task as done");
      ("-del", Arg.Set_int delete_arg, "Delete a task");
    ]
  in

  (* Ignore extra args *)
  let anon_fun _ = () in

  Arg.parse arg_spec anon_fun help_message;

  (* Determine filename to use *)
  let filename =
    match Sys.getenv_opt "TODO_FILENAME" with
    | Some value when value <> "" -> value
    | _ -> "todo.json"
  in

  match (!list_flag, !add_flag, !task_arg, !complete_arg, !delete_arg) with
  | true, _, _, _, _ -> CLI.list filename
  | _, _, _, idx, _ when idx > 0 -> CLI.complete filename idx
  | _, _, _, _, idx when idx > 0 -> CLI.delete filename idx
  | _, true, task_name, _, _ when task_name <> "" -> CLI.add filename task_name
  | _, true, _, _, _ -> add_task_from_stdin filename
  | _ -> failwith "Invalid option"
