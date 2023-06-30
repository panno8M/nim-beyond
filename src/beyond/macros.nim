import std/[
  macros,
  sequtils,
  options,
]
export
  macros except
    isExported

template quoteExpr*(bl: untyped): untyped = (quote do: bl)[0]

proc getName*(node: NimNode): NimNode =
  case node.kind
  of nnkIdent, nnkAccQuoted:
    return node
  of nnkPostfix:
    return node[1]
  of nnkPragmaExpr, nnkProcDef, nnkFuncDef:
    return node[0].getname
  else:
    error "The node is not supported for `getName`", node

proc replaceName*(node, value: NimNode): NimNode =
  case node.kind
  of nnkIdent, nnkAccQuoted, nnkSym:
    return value
  of nnkPostfix:
    return node.kind.newTree(node[0], value)
  of nnkPragmaExpr, nnkProcDef, nnkFuncDef:
    return node.kind.newTree(node[0].replaceName(value))
      .add node[1..^1]
  else:
    error "The node is not supported for `replaceName`: " & lisprepr node, node

func isExported*(node: NimNode): bool {.compileTime.} =
  case node.kind
  of nnkPostfix:
    return node[0].repr == "*"
  of nnkPragmaExpr, nnkProcDef, nnkFuncDef:
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

func getPragma*(node: NimNode; name: string): NimNode =
  node.expectKind {nnkProcDef, nnkFuncDef}
  for pragma in node.pragma:
    case pragma.kind
    of nnkCall, nnkCommand, nnkExprColonExpr:
      if pragma[0].eqIdent name:
        return pragma
    of nnkIdent, nnkSym:
      if pragma.eqIdent name:
        return pragma
    else:
      continue

func hasNoReturn*(node: NimNode): bool =
  node.expectKind {nnkProcDef, nnkFuncDef}
  node.params[0].kind == nnkEmpty or node.params[0].eqIdent("void")

func newCallFromParams*(name: NimNode; params: NimNode): NimNode =
  params.expectKind nnkFormalParams
  result = name.newCall(
    params[1..^1] # remove return_value
    .mapIt(it[0..^3]) # remove type and default_value
    .concat())

proc add*(s: NimNode; o: Option[NimNode]) =
  if o.isSome: s.add o

proc add*(s: NimNode; os: varargs[Option[NimNode]]) =
  for o in os:
    if o.isSome:
      s.add o