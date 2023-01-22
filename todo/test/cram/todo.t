Adding a new task
  $ todo -add "test task number 1"
  $ todo -list
  [ ] 1: test task number 1

Completing the task
  $ todo -complete 1
  $ todo -list
  [X] 1: test task number 1

Deleting a task
  $ todo -del 1
  $ todo -list

Adding a task from stdin
  $ printf "task from stdin\n" | todo -add
  $ todo -list
  [ ] 1: task from stdin

Adding multiple tasks at once from stdin
  $ printf "task a\ntask b\ntask c\n" | todo -add
  $ todo -list
  [ ] 1: task from stdin
  [ ] 2: task a
  [ ] 3: task b
  [ ] 4: task c

Setting the file name via an environment variable
  $ TODO_FILENAME=my_foo_list.json todo -add "t1"
  $ ls | grep 'my_foo_list.json'
  my_foo_list.json
  $ rm todo.json
  $ todo -list
  $ TODO_FILENAME=my_foo_list.json todo -list
  [ ] 1: t1
