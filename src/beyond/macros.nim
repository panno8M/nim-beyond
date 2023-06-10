import std/[
  macros,
  strformat,
]
export
  macros except
    isExported

template quoteExpr*(bl: untyped): untyped = (quote do: bl)[0]

proc setName*(a,val: NimNode): NimNode =
  result = a.copy
  case a.kind
  of nnkIdent, nnkAccQuoted:
    return val
  of nnkPostfix, nnkPrefix:
    result[1] = val
    return
  of nnkPragmaExpr:
    result[0] = a[0].setName(val)
  else:
    error(&"Do not know how to get name of ({lisprepr(a)})\n{repr(a)}", a)

proc getName*(a: NimNode): NimNode =
  case a.kind
  of nnkIdent, nnkAccQuoted:
    return a
  of nnkPostfix, nnkPrefix:
    return a[1]
  of nnkPragmaExpr:
    return a[0].getname
  else:
    error(&"Do not know how to get name of ({lisprepr(a)})\n{repr(a)}", a)

func isExported*(node: NimNode): bool {.compileTime.} =
  if node.kind == nnkPostfix: return node[0].repr == "*"
  if node.kind == nnkPragmaExpr: return node[0].isExported

func exportIf*(node: NimNode; cond: bool): NimNode {.compileTime.} =
  if cond: node.postfix("*")
  else: node

func replaceIdent*(node: NimNode; ident: string; dst: NimNode): NimNode =
  if node.len == 0: return
    if node.eqIdent ident: dst
    else: node
  result = node.kind.newNimNode()
  for n in node:
    result.add do:
      if n.eqIdent ident: dst
      else: n.replaceIdent(ident,dst)
  
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