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
    result = result.getImpl[2]
  if result.kind != nnkObjectTy: return nil
  else:
    result = result[1]
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
  var t  = Type
  let quoted = name.quoteOnce
  while not t.isNil:
    result = makeSymbol(t, quoted)
    if repr(result) in vmap: return
    t = t.getInherit
  return newEmptyNode()

macro getStatic*[T](Type: typedesc[T]; item): untyped =
  let t = Type
  case item.kind
  of nnkAccQuoted, nnkIdent, nnkSym:
    result = accessSymbol(t, item)
  else:
    result = item
    var task = result
    while task.len != 0 and task[0].len != 0:
      task = task[0]
    task[0] = accessSymbol(t, task[0])

proc defineStaticProc(Type, node: NimNode): NimNode =
  node.expectKind {nnkProcDef, nnkFuncDef, nnkConverterDef, nnkTemplateDef, nnkMacroDef}
  let sym = makeSymbol(Type, node[0].getname.quoteOnce)
  vmap.incl repr sym
  node[0] = node[0].replaceName(sym)
  node

proc defineStaticVariableSection(Type, node: NimNode): NimNode =
  node.expectKind {nnkVarSection, nnkLetSection, nnkConstSection}
  for def in node:
    case def.kind
    of nnkIdentDefs, nnkConstDef:
      for i in countup(0, def.len-3):
        let sym = makeSymbol(Type, def[i].getname.quoteOnce)
        vmap.incl repr sym
        def[i] = def[i].replaceName(sym)
    else: discard
  node

proc defineStaticTypeSection(Type, node: NimNode): NimNode =
  node.expectKind nnkTypeSection
  for def in node:
    case def.kind
    of nnkTypeDef:
      let sym = makeSymbol(Type, def[0].getname.quoteOnce)
      vmap.incl repr sym
      def[0] = def[0].replaceName(sym)
    else: discard
  node

proc staticOf_recursive(Type, node: NimNode): NimNode =
  const ignoreNodes = {nnkCommentStmt}
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
  of ignoreNodes:
    return node
  else:
    error &"There is currently no function to convert this section:\n" &
        node.lisprepr, node

macro staticOf*[T](Type: typedesc[T]; def): untyped =
  staticOf_recursive(Type, def)

proc convertAsgnToTypeDef(asgn: NimNode): NimNode =
  case asgn.kind
  of nnkAsgn:
    nnkTypeDef.newTree(
      asgn[0],
      newEmptyNode(),
      asgn[1]
    )
  else: asgn
macro `type`*(class: typedesc; def): untyped =
  let typesec = newNimNode nnkTypeSection
  case def.kind
  of nnkStmtList:
    for stmt in def:
      typesec.add convertAsgnToTypeDef stmt
  of nnkAsgn:
    typesec.add convertAsgnToTypeDef def
  else:
    typesec.add def

  result = defineStaticTypeSection(class, typesec)