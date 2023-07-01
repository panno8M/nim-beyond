import std/[
  strformat,
]
import ../[
  macros
]

const delim = "|>"

func newQuoted(items: varargs[NimNode]): NimNode =
  nnkAccQuoted.newTree(items)
func makeSymbol(Type, name: NimNode): NimNode =
  result = newQuoted ident repr(Type.getType[1]) & delim & $name
template replaceToStatic(node: untyped) =
  let baseName = node.getname
  let newName = makeSymbol(Type, baseName)
  node = node.replaceName(newName)

macro getStatic*[T](Type: typedesc[T]; item): untyped =
  var symbol: NimNode
  var whenValid: NimNode
  var whenInvalid: NimNode
  template symbolizeIdent(item: NimNode) =
      symbol = makeSymbol(Type, item)
      whenValid = symbol
      whenInvalid = Type.newDotExpr item
  block MAKE_TREE:
    case item.kind
    of nnkAccQuoted:
      symbolizeIdent item
    else:
      if item.len == 0:
        symbolizeIdent item
      else:
        whenValid = copy item
        var task = whenValid
        while task.len != 0 and task[0].len != 0:
          task = task[0]
        symbol = makeSymbol(Type, task[0])
        task[0] = symbol
        whenInvalid = copy item
        whenInvalid.insert(1, Type)
  result = quote do:
    when declared `symbol`:
      `whenValid`
    else:
      `whenInvalid`

proc defineStaticProc(Type, node: NimNode): NimNode =
  node.expectKind {nnkProcDef, nnkFuncDef, nnkConverterDef, nnkTemplateDef, nnkMacroDef}
  replaceToStatic(node[0])
  node

proc defineStaticVariableSection(Type, node: NimNode): NimNode =
  node.expectKind {nnkVarSection, nnkLetSection, nnkConstSection}
  for def in node:
    for i in countup(0, def.len-3):
      replaceToStatic(def[i])
  node

proc defineStaticTypeSection(Type, node: NimNode): NimNode =
  node.expectKind nnkTypeSection
  for def in node:
    replaceToStatic(def[0])
  node

proc staticOf_recursive(Type, node: NimNode): NimNode =
  case node.kind
  of nnkVarSection, nnkLetSection, nnkConstSection:
    return defineStaticVariableSection(Type, node)
  of nnkProcDef, nnkFuncDef, nnkConverterDef, nnkTemplateDef, nnkMacroDef:
    return defineStaticProc(Type, node)
  of nnkTypeSection:
    return defineStaticTypeSection(Type, node)
  of nnkStmtList:
    result = newStmtList()
    for child in node:
      result.add staticOf_recursive(Type, child)
  else:
    error &"There is currently no function to convert this section:\n" &
        node.lisprepr, node

macro staticOf*[T](Type: typedesc[T]; def): untyped =
  staticOf_recursive(Type, def)
