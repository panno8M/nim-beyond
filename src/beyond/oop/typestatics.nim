import std/[
  strformat,
]
import ../[
  macros,
  containerprelude,
]

type TypeID = string
var vmap {.compileTime.}: Table[TypeID, seq[NimNode]]

const delim = "|>"

proc getInherit(Type: NimNode): NimNode =
  if Type.kind != nnkSym: return nil
  result = Type.getImpl[2][1]
  if result.kind == nnkEmpty: return nil
  result = result[0]


func resolveTypeID(Type: NimNode): string =
  var r = Type.getType
  if r.kind == nnkObjectTy:
    r = Type
  else:
    r = r[1]
  repr r
func newQuoted(item: NimNode): NimNode =
  nnkAccQuoted.newTree(item)

func quoteOnce(item: NimNode): NimNode =
  if item.kind == nnkAccQuoted: return item
  newQuoted item

func makeSymbol(Type, name: NimNode): NimNode =
  quoteOnce ident resolveTypeID(Type) & delim & $name

proc accessSymbol(Type, name: NimNode): NimNode =
  if Type.isNil: return newEmptyNode()
  if name.quoteOnce in vmap.getOrDefault(resolveTypeID Type, @[]):
    return makeSymbol(Type, name)
  return accessSymbol(Type.getInherit, name)

func replaceToStatic(Type: NimNode; node: NimNode): NimNode =
  let baseName = node.getname
  let newName = makeSymbol(Type, baseName)
  result = node.replaceName(newName)


macro getStatic*[T](Type: typedesc[T]; item): untyped =
  var symbol: NimNode
  var whenValid: NimNode
  template symbolizeIdent(item: NimNode) =
      symbol = accessSymbol(Type, item)
      whenValid = symbol
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
        symbol = accessSymbol(Type, task[0])
        task[0] = symbol
  result = whenValid

proc defineStaticProc(Type, node: NimNode): NimNode =
  node.expectKind {nnkProcDef, nnkFuncDef, nnkConverterDef, nnkTemplateDef, nnkMacroDef}
  vmap.add(resolveTypeID Type, node[0].getname.quoteOnce)
  node[0] = Type.replaceToStatic(node[0])
  node

proc defineStaticVariableSection(Type, node: NimNode): NimNode =
  node.expectKind {nnkVarSection, nnkLetSection, nnkConstSection}
  for def in node:
    for i in countup(0, def.len-3):
      vmap.add(resolveTypeID Type, def[i].getname.quoteOnce)
      def[i] = Type.replaceToStatic(def[i])
  node

proc defineStaticTypeSection(Type, node: NimNode): NimNode =
  node.expectKind nnkTypeSection
  for def in node:
    vmap.add(resolveTypeID Type, def[0].getname.quoteOnce)
    def[0] = Type.replaceToStatic(def[0])
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
