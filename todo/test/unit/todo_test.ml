open Alcotest

let testable_task =
  let open Todo.Todo_list in
  testable
    (Fmt.Dump.record
       [
         Fmt.Dump.field "task" (fun t -> t.task) Fmt.string;
         Fmt.Dump.field "done" (fun t -> t.done_) Fmt.bool;
       ])
    (fun a b -> a.task = b.task && a.done_ = b.done_)

let list_tests =
  let open Todo in
  [
    test_case "A new list is empty" `Quick (fun () ->
        Todo_list.empty |> Todo_list.to_list
        |> Alcotest.(check @@ list testable_task) "List is empty" []);
    test_case "Adding a task creates an incomplete task with the given name"
      `Quick (fun () ->
        Todo_list.empty |> Todo_list.add_task "New task" |> Todo_list.to_list |> List.hd
        |> Alcotest.(check testable_task)
             "Task properly created"
             { task = "New task"; done_ = false });
    test_case "Tasks are listed in the order they're added" `Quick (fun () ->
        Todo_list.empty |> Todo_list.add_task "Task1" |> Todo_list.add_task "Task2"
        |> Todo_list.to_list
        |> List.map (fun t -> t.Todo.Todo_list.task)
        |> Alcotest.(check @@ list string)
             "Tasks are in expected order" [ "Task1"; "Task2" ]);
    test_case "Completing a task marks it as done" `Quick (fun () ->
        Todo_list.empty |> Todo_list.add_task "Task1" |> Todo_list.add_task "Task2"
        |> Todo_list.complete 1 |> Todo_list.to_list
        |> Alcotest.(check @@ list testable_task)
             "Correct task gets done_ set to true"
             [
               { task = "Task1"; done_ = true };
               { task = "Task2"; done_ = false };
      ]);
    test_case "Deleting a task removes it from the list" `Quick (fun () ->
        Todo_list.empty |> Todo_list.add_task "Task1" |> Todo_list.add_task "Task2"
        |> Todo_list.delete 1
        |> Todo_list.to_list
        |> Alcotest.(check @@ list testable_task)
             "Only one of the second task remains"
             [ { task = "Task2"; done_ = false } ]
      );
  ]

let serialization_tests =
  let input_of_string s =
    let idx = ref 0 in
    (fun buf len ->
       let actual_len = Int.min len (String.length s - !idx) in
       Bytes.blit_string s !idx buf 0 actual_len;
       idx := !idx + actual_len;
       actual_len)
  in
  let open Todo in
  [
    test_case
      "Serializing a list and loading it back yields an identical list"
      `Quick (fun () ->
        let todo_list = Todo_list.empty |> Todo_list.add_task "New task" in
        let serialized = Json.dump todo_list in
        Alcotest.(check @@ list testable_task)
          "Lists are identical" (Todo_list.to_list todo_list)
          (input_of_string serialized |> Json.load |> Result.get_ok |> Todo_list.to_list));
    test_case "Loading a todo list from a json string yields the expected list"
      `Quick (fun () ->
        let json_string =
          {|
           [{"task": "Json task",
           "done": true}]
           |}
        in
        Alcotest.(check @@ list testable_task)
          "Loaded list is as expected"
          (input_of_string json_string |> Json.load |> Result.get_ok |> Todo_list.to_list)
          [ { task = "Json task"; done_ = true } ]);
    test_case "Trying to load invalid json returns error" `Quick (fun () ->
        Alcotest.(check bool)
          "Is error" true
          (Result.is_error (input_of_string "[;.garbage>)" |> Json.load)));
    test_case
      "Trying to load a json that doesn't have an array at its root returns \
       error"
      `Quick (fun () ->
        Alcotest.(check bool)
          "Is error" true
          (Result.is_error (input_of_string "{}" |> Json.load)));
    test_case "Non-objects on the input json array result in an error" `Quick
      (fun () ->
        Alcotest.(check bool)
          "Is error" true
          (Result.is_error (input_of_string "[[1]]" |> Json.load)));
    test_case "Extra entries on a task get ignored" `Quick (fun () ->
        let json_string =
          {|
           [{"task": "Json task",
           "done": true,
           "foo": "bar"}]
           |}
        in
        Alcotest.(check @@ list testable_task)
          "Loaded list as if the extra field didn't exist"
          (input_of_string json_string |> Json.load |> Result.get_ok |> Todo_list.to_list)
          [ { task = "Json task"; done_ = true } ]);
    test_case "Missing fields are initialized to default values" `Quick
      (fun () ->
        Alcotest.(check @@ list testable_task)
          "Loaded task has default values"
          (input_of_string "[{}]" |> Json.load |> Result.get_ok |> Todo_list.to_list)
          [ { task = ""; done_ = false } ]);
  ]

let () =
  run "todo"
    [
      ("Todo-list tests", list_tests); ("Serialization of todo lists", serialization_tests);
      ("Persistence tests", File_persistence.tests);
      ("CLI App tests", Cli.tests);
    ]
