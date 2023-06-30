import std/[ sequtils, options, ]
import beyond/[ macros, ]

func makeKey(v: NimNode; length: int; name: string): tuple[def: Option[NimNode]; key: seq[NimNode]] =
  result.key = newSeq[NimNode](length)
  case v.kind
  of {nnkSym, nnkIdent}:
    for i, arg in result.key.mpairs:
      arg = nnkBracketExpr.newTree(v, newLit i)
  of nnkBracket:
    for i, arg in result.key.mpairs:
      arg = v[i]
  else:
    let arg0 = genSym(nskLet, name)
    result.def = some newIdentDefs(arg0, newEmptyNode(), v)
    for i, arg in result.key.mpairs:
      arg = nnkBracketExpr.newTree(arg0, newLit i)


template `<$>`*(container, pred): untyped =
  ## (<$>[1, 2, 3]: a * 2) == [2, 4, 6]
  container.fmap(pred)


macro fmap*[N: static int; T](Type: typedesc[array[N,T]]; pred): untyped =
  let typeofT = Type.getType[1][2]
  let elem = genSym(nskLet, "elem")
  let vec = nnkBracket.newTree elem.repeat(N)

  result = newStmtList(
    newLetStmt(elem, typeofT.newCall(pred)),
    vec)

macro fmap*[N: static int; T](v: array[N,T]; pred): untyped =
  var letsec = newNimNode nnkLetSection
  let
    (def0, key0) = makeKey(v, N, "arg0")

  letsec.add def0
  var bracket = newNimNode(nnkBracket)
  for i in 0..<N: bracket.add pred.replaceIdents(
    ("a", key0[i]),
    ("i", newLit i))

  result = newStmtList()
  if letsec.len != 0:
    result.add letsec
  result.add bracket

macro fmap*[N: static int; T,S](vs: (array[N,T], array[N,S]); pred): untyped =
  var letsec = newNimNode nnkLetSection
  let
    (def0, key0) = makeKey(vs[0], N, "arg0")
    (def1, key1) = makeKey(vs[1], N, "arg1")

  letsec.add def0, def1

  var bracket = newNimNode(nnkBracket)
  for i in 0..<N: bracket.add pred.replaceIdents(
      ("a", key0[i]),
      ("b", key1[i]),
      ("i", newLit i))

  result = newStmtList()
  if letsec.len != 0:
    result.add letsec
  result.add bracket

macro fmap*[N: static int; T,S,R](vs: (array[N,T], array[N,S], array[N,R]); pred): untyped =
  var letsec = newNimNode nnkLetSection
  let
    (def0, key0) = makeKey(vs[0], N, "arg0")
    (def1, key1) = makeKey(vs[1], N, "arg1")
    (def2, key2) = makeKey(vs[2], N, "arg2")

  letsec.add def0, def1, def2

  var bracket = newNimNode(nnkBracket)
  for i in 0..<N: bracket.add pred.replaceIdents(
      ("a", key0[i]),
      ("b", key1[i]),
      ("c", key2[i]),
      ("i", newLit i))

  result = newStmtList()
  if letsec.len != 0:
    result.add letsec
  result.add bracket
