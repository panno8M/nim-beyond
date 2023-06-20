{.experimental: "dynamicBindSym".}
import std/macros

macro defineProc*(typedef; body): untyped =
  if not (typedef.kind == nnkInfix and typedef[0].eqIdent "from"):
    error "Invalid syntax. Type: \ndefineProc `procName` from `procType`: `body`", typedef
  let name = typedef[1]
  let procty = bindSym(typedef[2], brOpen)
  result = nnkProcDef
    .newTree(name, newEmptyNode(), newEmptyNode())
    .add(procty.getImpl[0..^1])
    .add(newEmptyNode())
    .add newStmtList(body)

type GenProcKind = enum
  gpkPublicProc
  gpkPrivateProc
  gpkLambda
proc genProcImpl(procdef, name, body: NimNode; kind: GenProcKind): NimNode =
  let procty = procdef.getImpl[2]
  var newname: NimNode = copy name
  var newpragmas = copy procty[1]

  if newname.kind == nnkPragmaExpr:
    newpragmas.add newname[1][0..^1]
    newname  = newname[0]

  if kind == gpkPublicProc:
    newname = newname.postFix("*")

  let nodeKind = case kind
    of gpkLambda: nnkLambda
    else: nnkProcDef

  result = nodekind.newTree(
      newname,
      newEmptyNode(),
      newEmptyNode(),
      procty[0],
      # procty[1],
      newpragmas,
      newEmptyNode(),
      body)
  hint repr result, newname

macro genPrivateProcAs*(procdef: typedesc[proc]; name; body): untyped =
  genProcImpl(procdef, name, body, gpkPrivateProc)

macro genPublicProcAs*(procdef: typedesc[proc]; name; body): untyped =
  genProcImpl(procdef, name, body, gpkPublicProc)

macro genLambda*(procdef: typedesc[proc]; body): untyped =
  genProcImpl(procdef, newEmptyNode(), body, gpkLambda)

template `->`*(procdef: typedesc[proc]; name; body): untyped = genPrivateProcAs(procdef, name, body)
template `+>`*(procdef: typedesc[proc]; name; body): untyped = genPublicProcAs(procdef, name, body)
template `=>`*(procdef: typedesc[proc]; body): untyped = genLambda(procdef, body)