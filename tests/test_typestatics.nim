import beyond/oop/typestatics
import std/unittest

int.statics:
  var varitem*: int = 2
  let letitem*: int = 3
  const constitem*: int = 4

  var `!quoted!`*: int = 5

  proc initialize*(lvl: int) {.nimcall.} =
    discard
  proc `deinitialize`(lvl: int) =
    discard

  type localenum = enum
    e1, e2

  type LocalObject = object
    localitem: int

proc pow2(val: int): int {.staticOf: int.} = val*val

var varitem2 {.staticOf: int.} : int = 6
let letitem2 {.staticOf: int.} : int = 7
const constitem2 {.staticOf: int.} : int = 8

int.`!quoted!`= 1

test "typestatics":
  check int.varitem == 2
  int.varitem = 1
  check int.varitem == 1
  check int.letitem == 3
  check int.constitem == 4

  check int.localenum.e1 == `int.localenum`.e1

  let lobj {.used.} = int.LocalObject(localitem: 2)

  int.initialize(0)
  check int.pow2(10) == 100

  check int.varitem2 == 6
  int.varitem2 = 16
  check int.varitem2 == 16
  check int.letitem2 == 7
  check int.constitem2 == 8