module type Filesystem = sig
  val write : string -> string -> (unit, string) result
  val read : string -> (string, string) result
  val temp_file : string -> string
end

module Conversion = struct
  type content = {
    title: string;
    body: string;
    filename: string;
  }

  let apply_template {title; body; filename} template =
    Str.(
      template
      |> global_replace (regexp {|{{ .Title }}|}) title
      |> global_replace (regexp {|{{ .Body }}|}) body
      |> global_replace (regexp {|{{ .Filename }}|}) filename
    )

  (* This is to match the reference implementation (The Go blackfriday
     library).
     The injection is at this point still non-comprehensive, though;
     there's just enough to satisfy the tests for now.
  *)
  let rec inject_nofollow_inline = function
    | Omd.Link (attrs, elt) -> Omd.Link (("rel", "nofollow") :: attrs, elt)
    | Omd.Concat (attrs, elts) -> Omd.Concat(attrs, List.map inject_nofollow_inline elts)
    | elt -> elt

  let rec inject_nofollow = function
    | Omd.Paragraph (a, elt) -> Omd.Paragraph (a, inject_nofollow_inline elt)
    | Omd.List (a, b, c, blocks) -> Omd.List(a, b, c, List.map (fun lst -> List.map inject_nofollow lst) blocks)
    | elt -> elt

  let convert md =
    Omd.of_string md
    |> List.map inject_nofollow
    |> Omd.to_html ~auto_identifiers:false
    |> String.trim
end


(* Entry point module *)
module Make (Fs : Filesystem) : sig
  val preview : ?template:string -> string -> (string, string) result
end = struct
  let default_template =
    "<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">
    <title>{{ .Title }}: {{ .Filename }}</title>
  </head>
  <body>
{{ .Body }}
  </body>
</html>
"

  let (let*) = Result.bind
  let (>>=) = Result.bind
  let (>>|) a b = Result.map b a

  let read_template filename =
    match filename with
    | None -> Ok default_template
    | Some filename -> Fs.read filename

  let preview ?template filename =
    let open Conversion in
    let html_file = Fs.temp_file ".html" in
    let* template = read_template template in
    Fs.read filename
    >>| convert
    >>| (fun body -> apply_template {body; title = "Markdown Preview Tool" ; filename} template)
    >>= Fs.write html_file
    >>| Fun.const html_file
end
