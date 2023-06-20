import std/[
  strformat,
]
import ../[
  macros
]

proc defineStaticProc(Type,node: NimNode): NimNode =
  node.expectKind nnkProcDef
  let basename = node[0].getname
  let newprocname = nnkAccQuoted.newTree(ident &"{Type}.{basename}")
  let templatename = basename.exportIf(node[0].isExported)
  var args = copy(node.params)
  args.insert(1, newIdentDefs(ident"_", nnkBracketExpr.newTree(ident"typedesc", Type)))
  node[0] = node[0].setName(newprocname)
  let templatedef = newProc(
    name= templatename,
    params= args[0..^1],
    body= newStmtList(newprocname.newCallFromParams(node.params)),
    procType= nnkTemplateDef,
    pragmas= nnkPragma.newTree(ident"used"),
  )
  newStmtList()
    .add(node)
    .add(templatedef)

proc defineStaticVariableSection(Type,node: NimNode): NimNode =
  node.expectKind {nnkVarSection, nnkLetSection, nnkConstSection}

  let hasSetter = node.kind == nnkVarSection

  var setters = newSeqOfCap[NimNode](node.len)
  var getters = newSeqOfCap[NimNode](node.len)

  for def in node:
    for i in countup(0, def.len-3):
      let basename = def[i].getname
      let expt = def[i].isExported
      let newname = nnkAccQuoted.newTree(ident fmt"{Type}.{basename}")
      def[i] = def[i].setName(newname)

      let getter = nnkAccQuoted.newTree(basename).exportIf(expt)
      getters.add quote do:
        template `getter`(_: typedesc[`Type`]): typeof(`newname`) {.used.} = `newname`

      if not hasSetter: continue
      let setter = nnkAccQuoted.newTree(ident $basename&"=").exportIf(expt)
      setters.add quote do:
        template `setter`(_: typedesc[`Type`]; value: typeof(`newname`)) {.used.} = `newname` = value

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
      template `accessor`(_: typedesc[`Type`]): typedesc[`classname`] {.used.} = `classname`

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