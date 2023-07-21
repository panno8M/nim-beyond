import std/[options, sequtils, strutils, tables]
export options, sequtils, strutils, tables

import ./functional; export functional

type TableSeq*[Key, Value] = Table[Key, seq[Value]]
type TableSeqRef*[Key, Value] = TableRef[Key, seq[Value]]

proc add*[T](s: seq[T]; o: Option[T]) =
  if o.isSome: s.add o

proc add*[T](s: seq[T]; os: varargs[Option[T]]) =
  for o in os:
    if o.isSome:
      s.add o

proc add*[Key;Value](self: var Table[Key, seq[Value]]; key: Key; value: Value) =
  if self.hasKey key:
    self[key].add value
  else:
    self[key] = @[value]