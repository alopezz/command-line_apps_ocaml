module Filesystem_real = struct
  let write path contents =
    try
      Out_channel.with_open_text path
        (fun oc -> Out_channel.output_string oc contents)
      |> Result.ok
    with
      e -> Error ("Failed to write file: " ^ Printexc.to_string e)

  let read path =
    try
      In_channel.with_open_text path In_channel.input_all
      |> Result.ok
    with
      e -> Error ("Failed to read file: " ^ Printexc.to_string e)

  let temp_file suffix = Filename.temp_file "" suffix
end


module Mdp_real = Mdp.Make (Filesystem_real)

let help_message =
  "mdp [-file INPUT_FILE]\n\n\
   Preview markdown files.\n"

let preview_with_browser name =
  match Sys.os_type with
  | "Unix" ->
    if Sys.command @@ Filename.quote_command "xdg-open" [name] = 0 then
      Ok ()
    else
    if Sys.command @@ Filename.quote_command "open" [name] = 0 then
      Ok ()
    else
      Error "Failed to run command"

  | "Win32" ->
    if Sys.command @@ Filename.quote_command "cmd.exe" ["/C"; "start"; name] = 0 then
      Ok ()
    else
      Error "Failed to run command"

  | _ -> Error "OS not supported"


let () =
  let file_arg = ref "" in
  let skip_arg = ref false in
  let template_arg = ref None in

  let arg_spec =
    [
      ("-file", Arg.Set_string file_arg, "Input file");
      ("-s", Arg.Set skip_arg, "Skip preview");
      ("-t", Arg.String (fun t -> template_arg := Some t), "Custom template");
    ]
  in

  Arg.parse arg_spec ignore help_message;

  let preview = match !template_arg with
    | None -> fun x -> Mdp_real.preview x
    | Some filename -> Mdp_real.preview ~template:filename
  in

  let output_file =
    match preview !file_arg with
    | Ok output_file -> output_file
    | Error err ->
      print_endline err;
      exit 1
  in

  print_endline output_file;

  if not !skip_arg then (
    preview_with_browser output_file
    |> Result.iter_error (fun err -> print_endline err; exit 1);

    Unix.sleep 2;
    Unix.unlink output_file
  )
