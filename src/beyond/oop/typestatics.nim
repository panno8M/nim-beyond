import std/[
  strformat,
]
import ../[
  macros
]

proc defineStaticProc(Type,node: NimNode): NimNode =
  node.expectKind nnkProcDef
  let basename = node[0].getname
  let classname = nnkAccQuoted.newTree(ident &"{Type}.{basename}")
  let funcname = basename.exportIf(node[0].isExported)
  node[0] = node[0].setName(classname)
  newStmtList()
    .add(node)
    .add(quote do:
      template `funcname`(_: typedesc[`Type`]; args: varargs[untyped]): untyped {.used.} = `classname`(args)
   )

proc defineStaticVariableSection(Type,node: NimNode): NimNode =
  node.expectKind {nnkVarSection, nnkLetSection, nnkConstSection}

  let hasSetter = node.kind == nnkVarSection

  var setters = newSeqOfCap[NimNode](node.len)
  var getters = newSeqOfCap[NimNode](node.len)

  for def in node:
    let basename = def[0].getname
    let expt = def[0].isExported
    let classname = nnkAccQuoted.newTree(ident fmt"{Type}.{basename}")
    def[0] = def[0].setName(classname)

    let setter = nnkAccQuoted.newTree(ident fmt"{basename}=").exportIf(expt)
    let getter = nnkAccQuoted.newTree(ident fmt"{basename}").exportIf(expt)
    setters.add quote do:
      template `setter`(_: typedesc[`Type`]; args: varargs[untyped]): untyped {.used.} = `classname` = args
    getters.add quote do:
      template `getter`(_: typedesc[`Type`]): untyped {.used.} = `classname`

  result = newStmtList()
    .add(node)
    .add(getters)
  if hasSetter:
    result.add(setters)

proc defineStaticTypeSection(Type,node: NimNode): NimNode =
  node.expectKind nnkTypeSection

  var accessors = newSeqOfCap[NimNode](node.len)

  for def in node:
    def.expectKind nnkTypeDef
    let basename = def[0].getname
    let expt = def[0].isExported
    let classname = nnkAccQuoted.newTree(ident fmt"{Type}.{basename}")
    def[0] = def[0].setName(classname)

    let accessor = nnkAccQuoted.newTree(basename).exportIf(expt)
    accessors.add quote do:
      template `accessor`(_: typedesc[`Type`]): untyped {.used.} = `classname`

  newStmtList()
    .add(node)
    .add(accessors)


macro statics*[T](Type: typedesc[T]; body): untyped =
  template err(node: NimNode) = error &"There is currently no function to convert this section:\n" & node.lisprepr, node
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
  template err(node: NimNode) = error &"There is currently no function to convert this section:\n" & node.lisprepr, node
  case def.kind
  of nnkVarSection, nnkLetSection, nnkConstSection:
    return defineStaticVariableSection(Type, def)
  of nnkProcDef:
    return defineStaticProc(Type, def)
  else:
    err def