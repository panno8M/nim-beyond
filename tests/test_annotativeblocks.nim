import beyond/annotativeblocks
import beyond/meta/statements

const test1 = subject"test1"
const test2 = subject"test2"

TODO test1:
  echo "TEST1!"

TODO test2, false: # A sugar of `TODO test2: when false: ...`
  echo "TEST2!"
  undefinedProc()

BUG test1:
  echo "TEST1!"
  echo "TEST1!"

TODO test1

FIXME subject"withSubjectDefine":
  echo "With Subject"

FIXME test1
BUG test1

annotativeblocks.collect

echo report_markdown()