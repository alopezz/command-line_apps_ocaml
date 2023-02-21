(lang dune 3.5)

(name command-line_apps_ocaml)

(generate_opam_files true)

(source
 (github alopezz/command-line_apps_ocaml))

(authors "Alex Lopez")
(maintainers "Alex Lopez")

(license BSD-3-Clause)

;(documentation https://url/to/documentation)

(package
 (name wc)
 (synopsis "Word counter")
 (description "A clone of the classic wc utility.")
 (depends ocaml dune (alcotest (and :with-test (>= "1.6.0"))) (bisect_ppx (and :dev (>= "2.5.0")))))

(package
 (name todo)
 (synopsis "A todo list manager")
 (description "A basic CLI tool to manage tasks.")
 (depends ocaml dune (alcotest (and :with-test (>= "1.6.0"))) (bisect_ppx (and :dev (>= "2.5.0"))) (yojson (>= "2.0.2"))))

(package
 (name mdp)
 (synopsis "Markdown Preview Tool")
 (description "A tool to preview markdown files.")
 (depends ocaml dune (alcotest (and :with-test (>= "1.6.0"))) (bisect_ppx (and :dev (>= "2.5.0"))) (omd (="2.0.0.alpha3"))))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project