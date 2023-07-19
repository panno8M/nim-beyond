import beyond/annotativeblocks
import beyond/meta/statements

const test1 = subject"test1"
const test2 = subject"test2".setParent(test1)

TODO with test1:
  echo "TEST1!"

TODO with(test2, false): # A sugar of `TODO test2: when false: ...`
  echo "TEST2!"
  undefinedProc()

TODO with(test2, "with Comment and erase block", false): # A sugar of `TODO test2: when false: ...`
  echo "TEST2!"
  undefinedProc()

BUG with(test1, "This section has bug..."):
  # echo "BUG!"
  proc someproc() = (discard)

someproc()

TODO with(test1, "single-line")

FIXME with subject"withSubjectDefine":
  echo "With Subject"

FIXME with test1
BUG with test1

annotativeblocks.collect

echo report_markdown()