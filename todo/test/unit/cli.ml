(** Testing the cli module *)
open Alcotest

module Printer_fake = struct
  let out = Buffer.create 1000
  let get_output () = Buffer.contents out
  let clear () = Buffer.clear out

  let print s = Buffer.add_string out s
end

module Persistence_fake = struct
  let entries = Hashtbl.create 10
  let clear () = Hashtbl.reset entries
  
  let save name todo_list = Ok (Hashtbl.replace entries name todo_list)
  let load name = Ok (Hashtbl.find_opt entries name)
end

let tests =
  let module CLI = Todo.Cli.Make (Printer_fake) (Persistence_fake) in
  let default_name = "todo.json" in
  let test_case descr test =
    test_case descr `Quick (fun () -> Printer_fake.clear (); Persistence_fake.clear (); test ())
  in [
    test_case "Listing tasks when none have been added shows nothing"
      (fun () ->
         CLI.list default_name;
         Alcotest.(check string)
           "Empty output"
           ""
           (Printer_fake.get_output ()));
    test_case "Adding a task and then listing it shows the task being there"
      (fun () ->
         CLI.add default_name "test task number 1";
         CLI.list default_name;
         Alcotest.(check string)
           "Added task is present"
           "[ ] 1: test task number 1\n"
           (Printer_fake.get_output ())
      );
    test_case "Marking a task as complete shows it marked with an X when listing it"
      (fun () ->
         CLI.add default_name "test task number 1";
         CLI.complete default_name 1;
         CLI.list default_name;
         Alcotest.(check string)
           "Added task is present"
           "[X] 1: test task number 1\n"
           (Printer_fake.get_output ())
      );
    test_case "Adding two tasks creates them in order"
      (fun () ->
         CLI.add default_name "test task number 1";
         CLI.add default_name "test task number 2";
         CLI.list default_name;
         Alcotest.(check string)
           "Added task is present"
           "[ ] 1: test task number 1\n\
            [ ] 2: test task number 2\n"
           (Printer_fake.get_output ())
      );
    test_case "Completes the right task out of many"
      (fun () ->
         CLI.add default_name "test task number 1";
         CLI.add default_name "test task number 2";
         CLI.add default_name "test task number 3";
         CLI.complete default_name 2;
         CLI.list default_name;
         Alcotest.(check string)
           "Added task is present"
           "[ ] 1: test task number 1\n\
            [X] 2: test task number 2\n\
            [ ] 3: test task number 3\n"
           (Printer_fake.get_output ())
      );
    test_case "Deleting a task removes it from the list"
      (fun () ->
         CLI.add default_name "test task number 1";
         CLI.add default_name "test task number 2";
         CLI.add default_name "test task number 3";
         CLI.delete default_name 2;
         CLI.list default_name;
         Alcotest.(check string)
           "Added task is present"
           "[ ] 1: test task number 1\n\
            [ ] 2: test task number 3\n"
           (Printer_fake.get_output ())
      );
    test_case "Adding multiple tasks at once"
      (fun () ->
         CLI.add_bulk default_name ["task a"; "task b"; "task c"];
         CLI.list default_name;
         Alcotest.(check string)
           "Added task is present"
           "[ ] 1: task a\n\
            [ ] 2: task b\n\
            [ ] 3: task c\n"
           (Printer_fake.get_output ()));
    test_case "Adding a task to a list doesn't change another"
      (fun () ->
         CLI.add "other.json" "test task";
         CLI.list default_name;
         Alcotest.(check string)
           "No tasks"
           ""
           (Printer_fake.get_output ()));
    test_case "Error when loading a list for printing results in error message being printed"
      (fun () ->
         let error_msg = "oops" in
         let module Fail_on_load = struct
           include Persistence_fake
           let load _ = Error error_msg
         end
         in
         let module Bad_CLI = Todo.Cli.Make (Printer_fake) (Fail_on_load) in
         Bad_CLI.list default_name;
         Alcotest.(check string)
           "Error message"
           (Printf.sprintf "Loading error: %s\n" error_msg)
           (Printer_fake.get_output ()));
    test_case "Error when loading a list to operate on it results in error message being printed"
      (fun () ->
         let error_msg = "oops" in
         let module Fail_on_load = struct
           include Persistence_fake
           let load _ = Error error_msg
         end
         in
         let module Bad_CLI = Todo.Cli.Make (Printer_fake) (Fail_on_load) in
         Bad_CLI.add default_name "foo";
         Alcotest.(check string)
           "Error message"
           (Printf.sprintf "Loading error: %s\n" error_msg)
           (Printer_fake.get_output ()));
    test_case "Error when saving a list after operating on it results in error message being printed"
      (fun () ->
         let error_msg = "oops" in
         let module Fail_on_save = struct
           include Persistence_fake
           let save _ _ = Error error_msg
         end
         in
         let module Bad_CLI = Todo.Cli.Make (Printer_fake) (Fail_on_save) in
         Bad_CLI.add default_name "foo";
         Alcotest.(check string)
           "Error message"
           (Printf.sprintf "Saving error: %s\n" error_msg)
           (Printer_fake.get_output ()));
  ]
