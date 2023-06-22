import std/[
  strformat,
]
import ../[
  macros
]

const delim = "!!"

func newQuoted(items: varargs[NimNode]): NimNode =
  nnkAccQuoted.newTree(items)
func makeSName(Type, name: NimNode): NimNode =
  result = newQuoted ident repr(Type.getType[1]) & delim & $name
template replaceToStatic(node: untyped) =
  let baseName = node.getname
  let newName = makeSName(Type, baseName)
  node = node.replaceName(newName)

macro getStatic*[T](Type: typedesc[T]; item): untyped =
  result = item
  case result.kind
  of nnkAccQuoted:
    result = makeSName(Type, result)
  else:
    if result.len > 0:
      result[0] = makeSName(Type, result[0])
    else:
      result = makeSName(Type, result)

template `!!`*[T](Type: typedesc[T]; item): untyped =
  # It looks like '::' aren't you?
  Type.getStatic(item)


proc defineStaticProc(Type, node: NimNode): NimNode =
  node.expectKind nnkProcDef
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

macro statics*[T](Type: typedesc[T]; body): untyped =
  template err(node: NimNode) = error &"There is currently no function to convert this section:\n" &
      node.lisprepr, node
  result = newStmtList()
  for node in body:
    case node.kind
    of nnkVarSection, nnkLetSection, nnkConstSection:
      result.add defineStaticVariableSection(Type, node)
    of nnkProcDef:
      result.add defineStaticProc(Type, node)
    of nnkTypeSection:
      result.add defineStaticTypeSection(Type, node)
    else:
      err node

macro staticOf*[T](Type: typedesc[T]; def): untyped =
  template err(node: NimNode) = error &"There is currently no function to convert this section:\n" &
      node.lisprepr, node
  case def.kind
  of nnkVarSection, nnkLetSection, nnkConstSection:
    return defineStaticVariableSection(Type, def)
  of nnkProcDef:
    return defineStaticProc(Type, def)
  else:
    err def
