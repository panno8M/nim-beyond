## functions in this module will be moved in the future.

import std/strutils
type DeltaByte* = distinct uint64
type DeltaIndex* = distinct uint64

func `'dbyte`*(str: string): DeltaByte {.compileTime.} =
  DeltaByte str.parseInt
func `'didx`*(str: string): DeltaIndex {.compileTime.} =
  DeltaIndex str.parseInt

{.push, inline, raises: [].}
template dbyte*(i: uint|int): DeltaByte = DeltaByte i
func `+`*(a: uint64, b: DeltaByte): uint64 {.borrow.}
func `-`*(a: uint64, b: DeltaByte): uint64 {.borrow.}

template didx*(i: uint|int): DeltaIndex = DeltaIndex i
func `*`*(a: uint64, b: DeltaIndex): uint64 {.borrow.}

func succ*(p: pointer; dbyte: DeltaByte): pointer =
  cast[pointer](cast[uint64](p) + dbyte)
func pred*(p: pointer; dbyte: DeltaByte): pointer =
  cast[pointer](cast[uint64](p) - dbyte)

func succ*[T](p: ptr T; didx: DeltaIndex): ptr T =
  cast[ptr T](cast[uint64](p) + uint64(sizeof T) * didx)
func pred*[T](p: ptr T; didx: DeltaIndex): ptr T =
  cast[ptr T](cast[uint64](p) - uint64(sizeof T) * didx)

converter toPointer*[T](x: ptr T): pointer {.noSideEffect.} = cast[pointer](x)

func hex*(p: pointer): string = "0x" & cast[uint](p).toHex
func hex*[T](p: ptr[T]): string = "0x" & cast[uint](p).toHex
{.pop.}

template `+`*(p: pointer; dbyte: DeltaByte): pointer = p.succ(dbyte)
template `-`*(p: pointer; dbyte: DeltaByte): pointer = p.pred(dbyte)

template `+`*[T](p: ptr T; didx: DeltaIndex): ptr T = p.succ(didx)
template `-`*[T](p: ptr T; didx: DeltaIndex): ptr T = p.pred(didx)