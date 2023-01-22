(** Dumping to json **)

let to_yojson lst =
  let open Todo_list in
  `List
    (List.map
       (fun task ->
         `Assoc [ ("task", `String task.task); ("done", `Bool task.done_) ])
       lst)

let dump lst = Todo_list.to_list lst |> to_yojson |> Yojson.to_string

(** Loading from json **)

let task_from_json task_json =
  let open Todo_list in
  match task_json with
  | `Assoc pairs ->
      Ok
        (List.fold_left
           (fun result (key, value) ->
             match (key, value) with
             | "task", `String v -> { result with task = v }
             | "done", `Bool v -> { result with done_ = v }
             (* We simply ignore unrecognized entries for simplicity *)
             | _ -> result)
           { task = ""; done_ = false }
           pairs)
  | _ -> Error "Error parsing JSON"

let todo_list_from_json json =
  match json with
  | `List lst -> (
      let tasks = List.map task_from_json lst in
      match
        List.find_map (function Error err -> Some err | Ok _ -> None) tasks
      with
      | Some err -> Error err
      | None -> Ok (List.map Result.get_ok tasks |> Todo_list.of_list))
  | _ -> Error "Error parsing JSON, expected array but not found"

let json_from_lexbuf lexbuf =
  let lexer_state = Yojson.init_lexer () in
  try
    Ok (Yojson.Safe.from_lexbuf lexer_state lexbuf)
  with
    Yojson.Json_error err -> Error err

let load input =
  Result.bind
    (json_from_lexbuf @@ Lexing.from_function input)
    todo_list_from_json
