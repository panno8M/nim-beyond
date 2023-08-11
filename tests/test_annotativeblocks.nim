import beyond/annotativeblocks
import beyond/meta/statements

const test1 = subject"test1"
const test2 = subject"test2".setParent(test1)

TODO test1:
  echo "TEST1!"

TODO ignore test2: # A sugar of `TODO test2: when false: ...`
  echo "TEST2!"
  undefinedProc()

TODO ignore test2.comment"with Comment and erase block": # A sugar of `TODO test2: when false: ...`
  echo "TEST2!"
  undefinedProc()

BUG test1.comment"This section has bug...":
  # echo "BUG!"
  proc someproc() = (discard)

someproc()

TODO test1.comment"single-line"

FIXME subject"withSubjectDefine":
  echo "With Subject"

FIXME test1
BUG test1

annotativeblocks.collect

echo report_markdown()