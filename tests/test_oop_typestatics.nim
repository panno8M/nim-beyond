import beyond/oop
import std/unittest

template PRAGMA(args: varargs[untyped]) {.pragma.}

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
const ID* {.staticOf: MyOther.} = "MyOther"

type MyChild = object of MyObject
const ID* {.staticOf: MyChild.} = "MyChild"
let letitem* {.staticOf: MyChild.} = (MyObject|>letitem) * 2
proc proc_arg*(int_val: int): int {.staticOf: MyChild.} =
  int_val * 4

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

test "with typedesc":
  check (typedesc[MyObject])|>varitem == MyObject|>varitem
  proc x(T: typedesc[MyObject]) =
    check T|>varitem == MyObject|>varitem
  x(MyObject)

test "inheritance":
  check MyChild|>proc_arg(5) == 20
  check MyChild|>proc_arg != MyObject|>proc_arg

  MyChild|>proc_no_arg()
  check MyChild|>proc_no_arg == MyObject|>proc_no_arg

  check MyChild|>ID == "MyChild"

  check MyChild|>letitem == (MyObject|>letitem) * 2
  check (addr MyChild|>letitem) != (addr MyObject|>letitem)

test "generics":
  proc getID[T](t: typedesc[T]): string =
    t|>ID
  check getID(MyObject) == "MyObject"
  check getID(MyOther) == "MyOther"
  check getID(MyChild) == "MyChild"

  proc proc_arg_generic[T: MyObject|MyOther](int_val: int): int =
    T|>proc_arg(int_val)

  check proc_arg_generic[MyObject](3) == 6
  check proc_arg_generic[MyOther](3) == 9

test "type alias":
  MyObject.type:
    IntAlias {.PRAGMA.} = int
    ## test comment

  var x: MyObject|>IntAlias

  check typeof(x) is MyObject|>IntAlias
  check MyObject|>IntAlias is `MyObject|>IntAlias`
  check `MyObject|>IntAlias` is int

import typetraits
suite "Type resolving":
  test "distinct":
    type PTR = distinct pointer
    block:
      var ID {.used, staticOf: PTR.}: int
      check declared `PTR|>ID`
    block:
      var ID {.used, staticOf: distinctBase(PTR).}: int
      check declared `pointer|>ID`
  test "alias":
    type PTR = pointer
    block:
      var ID {.staticOf: PTR.}: int
      var HANDLE {.used, staticOf: pointer.}: int
      check declared `pointer|>ID`
      check declared `pointer|>HANDLE`
      check addr(PTR|>ID) == addr(pointer|>ID)
  test "inheritance":
    type INSTANCE = object of RootObj
    block:
      var ID {.staticOf: RootObj.}: int
      var DB {.staticOf: INSTANCE.}: int
      check declared `RootObj|>ID`
      check addr(RootObj|>ID) == addr(INSTANCE|>ID)
      check not declared `RootObj|>DB`
      check not declared `INSTANCE|>DB` # (moduleA.INSTANCE(INSTANCE_00000) != moduleB.INSTANCE(INSTNACE_00001))
      check INSTANCE|>DB == 0