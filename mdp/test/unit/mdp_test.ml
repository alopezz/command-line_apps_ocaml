module Filesystem_fake = struct
  let entries = Hashtbl.create 10
  let clear () = Hashtbl.reset entries

  let write name contents = Ok (Hashtbl.replace entries name contents)
  let read name =
    match Hashtbl.find_opt entries name with
    | Some c -> Ok c
    | None -> Error "File not found"
  let temp_file suffix =
    "random_name" ^ suffix
end


module Mdp_with_stubs = Mdp.Make (Filesystem_fake)


let basic_tests =
  let test_case descr test =
    Alcotest.test_case descr `Quick (fun () -> Filesystem_fake.clear (); test ())
  in
  [
    test_case "An empty markdown file results in a file being saved with just the template"
      (fun () ->
         Filesystem_fake.write "empty.md" "" |> Result.get_ok |> ignore;
         let path = Mdp_with_stubs.preview "empty.md" |> Result.get_ok in
         Alcotest.(check string) "Just the template"
           "<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">
    <title>Markdown Preview Tool: empty.md</title>
  </head>
  <body>

  </body>
</html>
"
            (Filesystem_fake.read path |> Result.get_ok)

      );
    test_case "An example markdown file gets rendered correctly with the default template"
      (fun () ->
         let markdown = "# Test Markdown File

Just a test

## Bullets:
* Links [Link1](https://example.com)

## Code Block
```
some code
```
" in
         Filesystem_fake.write "test1.md" markdown |> Result.get_ok |> ignore;
         let path = Mdp_with_stubs.preview "test1.md" |> Result.get_ok in
         Alcotest.(check string) "Equals golden file"
           "<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">
    <title>Markdown Preview Tool: test1.md</title>
  </head>
  <body>
<h1>Test Markdown File</h1>
<p>Just a test</p>
<h2>Bullets:</h2>
<ul>
<li>Links <a href=\"https://example.com\" rel=\"nofollow\">Link1</a>
</li>
</ul>
<h2>Code Block</h2>
<pre><code>some code
</code></pre>
  </body>
</html>
"
           (Filesystem_fake.read path |> Result.get_ok)
      );
    test_case "An example markdown file gets rendered correctly with an alternative template"
      (fun () ->
         let markdown = "# Test Markdown File

Just a test

## Bullets:
* Links [Link1](https://example.com)

## Code Block
```
some code
```
" in
         Filesystem_fake.write "test1.md" markdown |> Result.get_ok |> ignore;
         let template = {|<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8">
    <title>Title: {{ .Title }}</title>
  </head>
  <body>
    And this is the body:
{{ .Body }}
  </body>
</html>
|} in
         Filesystem_fake.write "custom_template.html" template |> Result.get_ok |> ignore;
         let path = Mdp_with_stubs.preview ~template:"custom_template.html" "test1.md" |> Result.get_ok in
         Alcotest.(check string) "Equals golden file"
           {|<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8">
    <title>Title: Markdown Preview Tool</title>
  </head>
  <body>
    And this is the body:
<h1>Test Markdown File</h1>
<p>Just a test</p>
<h2>Bullets:</h2>
<ul>
<li>Links <a href="https://example.com" rel="nofollow">Link1</a>
</li>
</ul>
<h2>Code Block</h2>
<pre><code>some code
</code></pre>
  </body>
</html>
|}
           (Filesystem_fake.read path |> Result.get_ok)
      );
  ]

let () =
  Alcotest.run "mdp tests"
    [
      ("basic functionality", basic_tests);
    ]
