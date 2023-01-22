(**
   Tests here deal with the lower-level details of file handling, testing the wrapper
   around [Stdlib] modules that implement actual IO ([Todo.File.Make_persistence]),
   simulating possible scenarios without actually touching the filesystem.
*)

open Alcotest

module Serializer_dummy = struct
  let dump _ = ""
  let load f =
    let _ = f (Bytes.create 10) 10 in
    Ok Todo.Todo_list.empty
end

module IO_dummy = struct
  type t = unit
  let with_open_text _ f = f ()
  let input _ _ _ _ = 0
  let output_string _ _ = ()
end

module File_system_dummy = struct
  module In = IO_dummy
  module Out = IO_dummy
  module Sys = struct
    let file_exists _ = true
  end
end

let tests_load = [
  test_case "Trying to load from a file that doesn't exist returns None" `Quick
    (fun () ->
       let module Non_existing_file = struct
         include File_system_dummy
         module Sys = struct
           let file_exists _ = false
         end
       end
       in
       let module Persistence = Todo.File.Make_persistence (Serializer_dummy) (Non_existing_file) in
       Alcotest.(check bool)
         "Is None" true
         (Persistence.load "something" |> Result.get_ok |> Option.is_none)
    );
  test_case "Trying to load from a file that doesn't exist returns None" `Quick
    (fun () ->
       let error_msg = "oops: something went wrong" in
       let module File_input_with_error_on_open = struct
         include File_system_dummy
         module In = struct
           include IO_dummy
           let with_open_text _ _ =
             raise (Sys_error error_msg)
         end
       end
       in
       let module Persistence = Todo.File.Make_persistence (Serializer_dummy) (File_input_with_error_on_open) in
       Alcotest.(check string)
         "Error message passes through"
         error_msg
         (Persistence.load "something" |> Result.get_error)
    );
  test_case "Exception raised from input results in error" `Quick
    (fun () ->
       let error_msg = "oops: something went wrong" in
       let module File_input_with_invalid_argument = struct
         include File_system_dummy
         module In = struct
           include IO_dummy
           let input _ _ _ _ = raise (Invalid_argument error_msg)
               end
       end
       in
       let module Persistence = Todo.File.Make_persistence (Serializer_dummy) (File_input_with_invalid_argument) in
       Alcotest.(check string)
         "Error message passes through"
         error_msg
         (Persistence.load "something" |> Result.get_error)
    );
  test_case "Error in serializer on load gets propagated" `Quick
    (fun () ->
       let error_msg = "oops: something went wrong" in
       let module Error_serializer = struct
         include Serializer_dummy
         let load _f = Error error_msg
       end
       in
       let module Persistence = Todo.File.Make_persistence (Error_serializer) (File_system_dummy) in
       Alcotest.(check string)
         "Error message passes through"
         error_msg
         (Persistence.load "something" |> Result.get_error)
    );
  test_case "Input data gets used to build a list when everything goes well" `Quick
    (fun () ->
       let list_name = "list name" in
       let task_name = "test task 1" in
       (* A serializer that simply creates a list with one task, the
          task taken from the input as is. *)
       let module Serializer_single_task = struct
         include Serializer_dummy
         let load f =
           let buf = Bytes.create 100 in
           let len = f buf 100 in
           Ok Todo.Todo_list.(empty |> add_task @@ Bytes.sub_string buf 0 len)
       end
       in
       let module String_in_fs = struct
         include File_system_dummy
         module In = struct
           type t = { contents : string; mutable idx : int}
           let make contents = { contents; idx = 0 }

           let with_open_text s f =
             f @@ make (if s = list_name then task_name else "")

           let input ({ contents; idx } as in_channel) buf pos len =
             (* Cap bytes read according to what's actually left on the string *)
             let actual_len = Int.min len (String.length contents - idx) in
             Bytes.blit_string contents idx buf pos actual_len;
             in_channel.idx <- idx + actual_len;
             actual_len
         end
       end
       in
       let module Persistence = Todo.File.Make_persistence (Serializer_single_task) (String_in_fs) in
       Alcotest.(check string)
         "We get the expected task"
         task_name
         (Persistence.load list_name |> Result.get_ok |> Option.get |> Todo.Todo_list.to_list |> List.hd).task
    );
]

let tests_save = [
  test_case "Saving a list to a file outputs a serialized version to the channel" `Quick
    (fun () ->
       let list_name = "list name" in
       let task_names = ["task 1"; "task 2"] in
       let module Task_deserializer = struct
         include Serializer_dummy
         let dump todo_list =
           Todo.Todo_list.(to_list todo_list
                           |> List.map (fun task -> task.task)
                           |> String.concat "\n")
       end
       in
       let module String_out_fs = struct
         include File_system_dummy
         module Out = struct
           type t = string ref
           let b = ref ""

           let with_open_text s f =
             Alcotest.(check string) "The right file is opened" list_name s;
             b := "";
             f (b)

           let output_string c s =
             c := s
         end
       end
       in
       let module Persistence = Todo.File.Make_persistence (Task_deserializer) (String_out_fs) in
       Alcotest.(check string)
         "The right task has been saved"
         (task_names |> String.concat "\n")
         (let todo_list = Todo.Todo_list.(empty |> (Fun.flip (List.fold_left (fun lst tsk -> add_task tsk lst)) task_names)) in
          let () = Persistence.save list_name todo_list |> Result.get_ok in
          !String_out_fs.Out.b
         )
    );
  test_case "Returns error when something goes wrong while trying to open the file" `Quick
    (fun () ->
       let module Open_out_failure = struct
         include File_system_dummy

         module Out = struct
           include IO_dummy

           let with_open_text _ _ =
             raise (Sys_error "Failed to open the file")
         end
       end
       in
       let module Persistence = Todo.File.Make_persistence (Serializer_dummy) (Open_out_failure) in
       Alcotest.(check bool)
         "The result is error"
         true
         (Persistence.save "somewhere" (Todo.Todo_list.empty) |> Result.is_error)
    );
  test_case "Returns error when something goes wrong while outputting to file" `Quick
    (fun () ->
       let module Output_failure = struct
         include File_system_dummy

         module Out = struct
           include IO_dummy

           let output_string _ _ =
             raise (Sys_error "Read failure")
         end
       end
       in
       let module Persistence = Todo.File.Make_persistence (Serializer_dummy) (Output_failure) in
       Alcotest.(check bool)
         "The result is error"
         true
         (Persistence.save "somewhere" (Todo.Todo_list.empty) |> Result.is_error)
    );
]

let tests =
  List.concat
    [tests_load; tests_save]
