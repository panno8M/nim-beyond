import std/[
  strformat,
  sets,
]
import ../[
  macros,
]

type BoundSym = string
var vmap {.compileTime.}: HashSet[BoundSym]

const delim = "|>"

proc getInherit(Type: NimNode): NimNode =
  result = Type
  if result.kind == nnkSym:
    result = result.getImpl[2][1]
  if result.kind == nnkEmpty: return nil
  result = result[0]


func resolveTypeID(Type: NimNode): string =
  var r = Type.getType
  case r.kind
  of nnkObjectTy:
    r = Type
  of nnkBracketExpr:
    r = r[1]
  else:
    discard
  repr r
func newQuoted(item: NimNode): NimNode =
  nnkAccQuoted.newTree(item)

func quoteOnce(item: NimNode): NimNode =
  if item.kind == nnkAccQuoted: return item
  newQuoted item

func makeSymbol(Type, name: NimNode): NimNode =
  result = quoteOnce ident resolveTypeID(Type) & delim & $name
  result.setLineInfo(name.lineInfoObj())

proc accessSymbol(Type, name: NimNode): NimNode =
  var Type  = Type
  var quoted: NimNode
  while not Type.isNil:
    quoted = name.quoteOnce
    result = makeSymbol(Type, name.quoteOnce)
    if $result in vmap: return
    Type = Type.getInherit
  return newEmptyNode()

macro getStatic*[T](Type: typedesc[T]; item): untyped =
  case item.kind
  of nnkAccQuoted, nnkIdent, nnkSym:
    result = accessSymbol(Type, item)
  else:
    result = item
    var task = result
    while task.len != 0 and task[0].len != 0:
      task = task[0]
    task[0] = accessSymbol(Type, task[0])

proc defineStaticProc(Type, node: NimNode): NimNode =
  node.expectKind {nnkProcDef, nnkFuncDef, nnkConverterDef, nnkTemplateDef, nnkMacroDef}
  let sym = makeSymbol(Type, node[0].getname)
  vmap.incl $sym
  node[0] = node[0].replaceName(sym)
  node

proc defineStaticVariableSection(Type, node: NimNode): NimNode =
  node.expectKind {nnkVarSection, nnkLetSection, nnkConstSection}
  for def in node:
    for i in countup(0, def.len-3):
      let sym = makeSymbol(Type, def[i].getname)
      vmap.incl $sym
      def[i] = def[i].replaceName(sym)
  node

proc defineStaticTypeSection(Type, node: NimNode): NimNode =
  node.expectKind nnkTypeSection
  for def in node:
    let sym = makeSymbol(Type, def[0].getname)
    vmap.incl $sym
    def[0] = def[0].replaceName(sym)
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
