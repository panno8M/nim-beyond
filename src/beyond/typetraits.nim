import std/macros
import std/typetraits; export typetraits except
  get

type InvalidType* = object
macro `||`*(a,b: typedesc): typedesc =
  if not a.eqIdent $InvalidType:
    a
  elif not b.eqIdent $InvalidType:
    b
  else:
    bindSym "InvalidType"

macro typeOfField*(t: typedesc[tuple]; index: static int): untyped =
  let ttype {.inject.} = t.getType[1]
  let i = index+1
  if i in 1..<(ttype.len): # ttype[0] == ident "tuple"
    return t.getType[1][i]
  else:
    return bindSym "InvalidType"

when isMainModule:
  type OBJECT[T: tuple] = object
  type TUPLE = tuple[a, b: int; c, d: float]
  type TUPLE_OBJ = OBJECT[TUPLE]
  {.hint: $TUPLE_OBJ.T.tuplelen.}
  {.hint: $TUPLE_OBJ.T.typeOfField(3).}
  {.hint: $(TUPLE_OBJ.T.typeOfField(4) || InvalidType || object).}
  {.hint: $(InvalidType || int).}