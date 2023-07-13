import beyond/oop
import std/unittest

type MyInt = int
staticOf MyInt:
  var varitem*: int = 2
  let letitem*: int = 3
  const constitem*: int = 4

  var multiitem1*, multiitem2: int

  var `!quoted!`*: int = 5

  const ID* = "MyInt"

staticOf int:
  proc proc_arg*(int_val: int): int = int_val * 2
  proc `proc_no_arg`() {.nimcall.} = discard

  type localenum = enum
    e1, e2

  type LocalObject = object
    localitem: int

proc proc_by_pragma(val: int): int {.staticOf: int.} = val*2

var varitem_by_pragma {.staticOf: int.}: int = 6
let letitem_by_pragma {.staticOf: int.}: int = 7
const constitem_by_pragma {.staticOf: int.}: int = 8

proc proc_arg*(int_val: int): int {.staticOf: float.} =
  int_val * 3

int|>`!quoted!` = 1

test "access to static variables":
  check int|>varitem == 2
  int|>varitem = 1
  check int|>varitem == 1
  check int|>letitem == 3
  check int|>constitem == 4

  discard MyInt|>varitem

  int|>multiitem1 = 1
  int|>multiitem2 = 2

  check int|>proc_by_pragma(5) == 10

  check int|>varitem_by_pragma == 6
  int|>varitem_by_pragma = 16
  check int|>varitem_by_pragma == 16
  check int|>letitem_by_pragma == 7
  check int|>constitem_by_pragma == 8

  check MyInt|>ID == int|>ID
  check $(MyInt|>ID) == "MyInt"
  # $MyInt|>ID -> Syntax error! (== ($MyInt)|>ID )
  check $MyInt.getStatic(ID) == "MyInt"

test "access to static types":
  check int|>localenum.e1 == `int|>localenum`.e1

  let lobj {.used.} = int|>LocalObject(localitem: 2)

test "access to static procs":
  check int|>proc_arg(5) == 10
  check `int|>proc_arg`(5) == 10
  int|>proc_no_arg()
  let proc_arg_ptr = int|>proc_arg
  let proc_no_arg_ptr = int|>proc_no_arg
  check proc_arg_ptr(2) == 4
  proc_no_arg_ptr()
  let proc_no_arg_ptr2 {.used.} = `int|>proc_no_arg`

  proc proc_arg_generic[T: int|float](int_val: int): int =
    T|>proc_arg(int_val)

  check proc_arg_generic[int](3) == 6
  check proc_arg_generic[float](3) == 9