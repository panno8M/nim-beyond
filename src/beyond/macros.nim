import std/[
  macros,
  strformat,
]
export
  macros except
    isExported

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