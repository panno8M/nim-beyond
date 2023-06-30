import std/[options, sequtils, strutils]
export options, sequtils, strutils

import ./functional; export functional

proc add*[T](s: seq[T]; o: Option[T]) =
  if o.isSome: s.add o

proc add*[T](s: seq[T]; os: varargs[Option[T]]) =
  for o in os:
    if o.isSome:
      s.add o
