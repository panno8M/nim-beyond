import std/[
  macros,
  sequtils,
  options,
]
export
  macros except
    isExported

proc getName*(node: NimNode): NimNode =
  case node.kind
  of nnkIdent, nnkAccQuoted, nnkSym:
    return node
  of nnkPostfix:
    return node[1]
  of nnkPragmaExpr, RoutineNodes:
    return node[0].getname
  else:
    error "The node is not supported for `getName`", node

proc replaceName*(node, value: NimNode): NimNode =
  case node.kind
  of nnkIdent, nnkAccQuoted, nnkSym:
    return value
  of nnkPostfix:
    return node.kind.newTree(node[0], value)
  of nnkPragmaExpr, RoutineNodes:
    return node.kind.newTree(node[0].replaceName(value))
      .add node[1..^1]
  else:
    error "The node is not supported for `replaceName`: " & lisprepr node, node

func isExported*(node: NimNode): bool {.compileTime.} =
  case node.kind
  of nnkPostfix:
    return node[0].repr == "*"
  of nnkPragmaExpr, RoutineNodes:
    return node[0].isExported
  else:
    return false

func postfixIf*(node: NimNode; op: string; cond: bool): NimNode {.compileTime.} =
  if cond: node.postfix(op)
  else: node
func exportIf*(node: NimNode; cond: bool): NimNode {.compileTime.} =
  node.postfixIf("*", cond)

func replaceIdents*(node: NimNode; idents: varargs[tuple[key: string; value: NimNode]]): NimNode =
  if node.len == 0:
    for ident in idents:
      if node.eqIdent ident.key: return ident.value
  else:
    for i in 0..<node.len:
      node[i] = node[i].replaceIdents(idents)
  return node
func replaceIdents*(node: NimNode; idents: varargs[NimNode]): NimNode =
  if node.len == 0:
    for ident in idents:
      if node.eqIdent ident: return ident
  else:
    for i in 0..<node.len:
      node[i] = node[i].replaceIdents(idents)
  return node

func getOrPopPragma(node: NimNode; name: string; pop: bool): NimNode =
  node.expectKind RoutineNodes
  for i, pragma in node.pragma:
    case pragma.kind
    of nnkCall, nnkCommand, nnkExprColonExpr:
      if pragma[0].eqIdent name:
        result = pragma
        if pop: node.pragma.del(i)
        return
    of nnkIdent, nnkSym:
      if pragma.eqIdent name:
        result = pragma
        if pop: node.pragma.del(i)
        return
    else:
      continue
func getPragma*(node: NimNode; name: string): NimNode =
  getOrPopPragma(node, name, false)
func popPragma*(node: NimNode; name: string): NimNode =
  getOrPopPragma(node, name, true)

func hasNoReturn*(node: NimNode): bool =
  node.expectKind RoutineNodes
  node.params[0].kind == nnkEmpty or node.params[0].eqIdent("void")

proc hasReturn*(node: NimNode): bool =
  not node.hasNoReturn

iterator breakArgs*(node: NimNode): tuple[index: int; def: tuple[name, Type, default: NimNode]] =
  node.expectKind nnkFormalParams
  var index: int
  for defs in node[1..^1]:
    for id in defs[0..^3]:
      yield (index, (id, defs[^2], defs[^1]))
      inc index

func newCallFromParams*(name: NimNode; params: NimNode): NimNode =
  params.expectKind nnkFormalParams
  result = name.newCall(
    params[1..^1] # remove return_value
    .mapIt(it[0..^3]) # remove type and default_value
    .concat())

func newAddr*(node: NimNode): NimNode = nnkAddr.newTree(node)
func newUnsafeAddr*(node: NimNode): NimNode = ident("unsafeAddr").newCall(node)

proc add*(s: NimNode; o: Option[NimNode]) =
  if o.isSome: s.add o

proc add*(s: NimNode; os: varargs[Option[NimNode]]) =
  for o in os:
    if o.isSome:
      s.add o

proc stmtList_to_seq*(stmtList: NimNode; conv: string): NimNode =
  nnkBracket.newTree(
    stmtList[0..^1].mapIt(conv.newCall it)
  ).prefix("@")

proc variableSection_to_exprs*(section: NimNode): seq[NimNode] =
  assert section.kind in {nnkVarSection, nnkLetSection}
  for identdefs in section:
    let t = identdefs[^2]
    let v = identdefs[^1]
    for nameWithDeco in identdefs[0..^3]:
      let name = nameWithDeco.getName
      if section.kind == nnkVarSection:
        result.add quote do:
          (var `nameWithDeco`: `t` = `v`; `name`)
      elif section.kind == nnkLetSection:
        result.add quote do:
          (let `nameWithDeco`: `t` = `v`; `name`)

macro stringifySymbol*(x: untyped): string = toStrLit x