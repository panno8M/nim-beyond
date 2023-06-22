{.experimental: "dynamicBindSym".}
import ../macros

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
  var newname = name
  var newpragmas = procty[1]

  var newparams = copy procty[0]
  var argnames: seq[NimNode]
  for newparam in newparams:
    if newparam.kind != nnkIdentDefs: continue
    for i in 0..(newparam.len-3):
      newparam[i] = genSym(nskParam, $newparam[i])
      argnames.add newparam[i]

  var newbody = body
    .replaceIdents(argnames)

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
      newparams,
      newpragmas,
      newEmptyNode(),
      newbody)

macro genPrivateProcAs*(procdef: typedesc[proc]; name; body): untyped =
  genProcImpl(procdef, name, body, gpkPrivateProc)

macro genPublicProcAs*(procdef: typedesc[proc]; name; body): untyped =
  genProcImpl(procdef, name, body, gpkPublicProc)

macro genLambda*(procdef: typedesc[proc]; body): untyped =
  genProcImpl(procdef, newEmptyNode(), body, gpkLambda)

template `=>`*(procdef: typedesc[proc]; name; body): untyped = genPrivateProcAs(procdef, name, body)
template `=>*`*(procdef: typedesc[proc]; name; body): untyped = genPublicProcAs(procdef, name, body)
template `=>`*(procdef: typedesc[proc]; body): untyped = genLambda(procdef, body)