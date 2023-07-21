import beyond/oop
import std/unittest

type MyObject = object of RootObj
staticOf MyObject:
  var varitem*: int = 2
  let letitem*: int = 3
  const constitem*: int = 4

  var multiitem1*, multiitem2: int

  var `!quoted!`*: int = 5

  const ID* = "MyObject"

type MyAlias = MyObject
staticOf MyAlias:
  proc proc_arg*(int_val: int): int = int_val * 2
  proc `proc_no_arg`() {.nimcall.} = discard

  type localenum = enum
    e1, e2

  type LocalObject = object
    localitem: int

proc proc_by_pragma(val: int): int {.staticOf: MyObject.} = val*2

var varitem_by_pragma {.staticOf: MyObject.}: int = 6
let letitem_by_pragma {.staticOf: MyObject.}: int = 7
const constitem_by_pragma {.staticOf: MyObject.}: int = 8

type MyOther = object
proc proc_arg*(int_val: int): int {.staticOf: MyOther.} =
  int_val * 3

type MyChild = object of MyObject

MyObject|>`!quoted!` = 1

test "access to static variables":
  check MyObject|>varitem == 2
  MyObject|>varitem = 1
  check MyObject|>varitem == 1
  check MyObject|>letitem == 3
  check MyObject|>constitem == 4

  discard MyObject|>varitem

  MyObject|>multiitem1 = 1
  MyObject|>multiitem2 = 2

  check MyObject|>proc_by_pragma(5) == 10

  check MyObject|>varitem_by_pragma == 6
  MyObject|>varitem_by_pragma = 16
  check MyObject|>varitem_by_pragma == 16
  check MyObject|>letitem_by_pragma == 7
  check MyObject|>constitem_by_pragma == 8

  check MyObject|>ID == MyObject|>ID
  check $(MyObject|>ID) == "MyObject"
  # $MyObject|>ID -> Syntax error! (== ($MyObject)|>ID )
  check $MyObject.getStatic(ID) == "MyObject"

test "access to static types":
  check MyObject|>localenum.e1 == `MyObject|>localenum`.e1

  let lobj {.used.} = MyObject|>LocalObject(localitem: 2)

test "access to static procs":
  check MyObject|>proc_arg(5) == 10
  check `MyObject|>proc_arg`(5) == 10
  MyObject|>proc_no_arg()
  let proc_arg_ptr = MyObject|>proc_arg
  let proc_no_arg_ptr = MyObject|>proc_no_arg
  check proc_arg_ptr(2) == 4
  proc_no_arg_ptr()
  let proc_no_arg_ptr2 {.used.} = `MyObject|>proc_no_arg`

  proc proc_arg_generic[T: MyObject|MyOther](int_val: int): int =
    T|>proc_arg(int_val)

  check proc_arg_generic[MyObject](3) == 6
  check proc_arg_generic[MyOther](3) == 9

test "inheritance":
  check MyChild|>proc_arg(5) == 10
  check MyChild|>proc_arg == MyObject|>proc_arg