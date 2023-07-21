import std/unittest
import beyond/ptrtraits

suite "ptrtraits":
  var x = (0x1020304'u32, 0x5060708'u32, 0x90A0B0C'u32)
  test "ptr T (+/-) index":
    let ad = addr x[1]
    check (ad - 1'didx)[] == 0x1020304
    check (ad - 0'didx)[] == 0x5060708
    check (ad + 0'didx)[] == 0x5060708
    check (ad + 1'didx)[] == 0x90A0B0C
  test "pointer (+/-) bytes":
    let ad = cast[ptr uint8](cast[uint64](addr x[0]) + 1)
    let arr = cast[ptr array[4, byte]](addr x[0])[]
    check cast[ptr uint8](ad - 1'dbyte)[] == arr[0]
    check cast[ptr uint8](ad - 0'dbyte)[] == arr[1]
    check cast[ptr uint8](ad + 0'dbyte)[] == arr[1]
    check cast[ptr uint8](ad + 1'dbyte)[] == arr[2]
  test "unchecked array":
    let ad = cast[ptr UncheckedArray[uint32]](addr x[1])
    check (ad - 1'didx)[] == 0x1020304
    check (ad - 0'didx)[] == 0x5060708
    check (ad + 0'didx)[] == 0x5060708
    check (ad + 1'didx)[] == 0x90A0B0C