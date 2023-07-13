import std/[
  sequtils,
  strutils,
  strformat,
  tables,
  sets,
  hashes,
  os,
  algorithm,
]
import ./statements
import ../macros

const modulegenInfo_template = staticRead("./beyond/meta/modules/modulegenInfo_template.nims")

proc hash*[T](x: ref[T]): Hash {.inline.} =
  hash(cast[pointer](x))

type
  DTFlag* = enum
    dtfDummy
    dtfInternal
template All*(_: typedesc[set[DTFlag]]): set[DTFlag] =
  {dtfDummy, dtfInternal}
type
  RelationSetting* = enum
    rsInherit
    rsAllowImport
    rsAllowImportAndExport
  ExportSetting* = enum
    esDontExport
    esExportAllowed
    esExportAll

  Cloud* = ref object
    name*: string
    subClouds*: HashSet[Cloud]
    modules*: HashSet[Module]

  DTNode* = ref object of RootObj ## Directory-Tree Node
    name*: string
    flags*: set[DTFlag]
    relationSetting*: RelationSetting = rsInherit
    parent*: Directory
    cloud*: Cloud

  Directory* = ref object of DTNode
    modules*: Table[string, Module]
    subdirs*: Table[string, Directory]

  Module* = ref object of DTNode
    exportSetting*: ExportSetting = esDontExport
    contents*: Statement = ParagraphSt()
    header*: string = "## This module was generated automatically. Changes will be lost."

const moduleExt*: string = ".nim"
method nameWithExt*(node: DTNode): string {.base.} = node.name
method nameWithExt*(module: Module): string = module.name & moduleExt

func dumpName(cloud: Cloud): string =
  var name = cloud.name
  if name.isEmptyOrWhitespace:
    name = "cloud_@" & cast[uint64](cloud).toHex()
  result = "{{" & name & "}}"

func dumpName(module: Module; mask = set[DTFlag].All): string =
  result = module.nameWithExt
  let masked = mask * module.flags
  if dtfInternal in masked: result = "." & result
  if dtfDummy in masked: result = "(" & result & ")"

func dumpName(directory: Directory; mask = set[DTFlag].All): string =
  result = directory.name & "/"
  let masked = mask * directory.flags
  if dtfInternal in masked: result = "." & result
  if dtfDummy in masked: result = "(" & result & ")"

proc unpackModules*(dir: Directory; depth = Natural.high): HashSet[Module] =
  if depth == 0: return
  for name, module in dir.modules:
    result.incl module
  for name, subd in dir.subdirs:
    result.incl subd.unpackModules(depth.pred)

proc incl*[T](s: var HashSet[T]; items: varargs[T]) =
  for i in items: s.incl i
proc incl*(s: var HashSet[Cloud]; directories: varargs[Directory]) =
  for d in directories: s.incl d.cloud

proc incl*(cloud: Cloud; subclouds: HashSet[Cloud]): Cloud =
  result = cloud; cloud.subClouds.incl subclouds
proc incl*(cloud: Cloud; subclouds: varargs[Cloud]): Cloud =
  result = cloud; cloud.subClouds.incl subclouds
proc incl*(cloud: Cloud; modules: HashSet[Module]): Cloud =
  result = cloud; result.modules.incl modules
proc incl*(cloud: Cloud; modules: varargs[Module]): Cloud =
  result = cloud; result.modules.incl modules
proc incl*(cloud: Cloud; dirs: varargs[Directory]): Cloud =
  result = cloud; result.subClouds.incl dirs

proc incl*(module: Module; modules: HashSet[Module]): Module =
  result = module; result.cloud.modules.incl modules
proc incl*(module: Module; modules: varargs[Module]): Module =
  result = module; result.cloud.modules.incl modules
proc incl*(module: Module; clouds: HashSet[Cloud]): Module =
  result = module; result.cloud.subClouds.incl clouds
proc incl*(module: Module; clouds: varargs[Cloud]): Module =
  result = module; result.cloud.subClouds.incl clouds
proc incl*(module: Module; dirs: varargs[Directory]): Module =
  result = module; result.cloud.subClouds.incl dirs

proc cloud*(name: string): Cloud =
  Cloud(name: name)

proc mdl*(name: string; flags: set[DTFlag] = {}): Module =
  Module(
    name: name,
    flags: flags,
    cloud: cloud(name&"_cloud"),
  )
proc dir*(name: string; flags: set[DTFlag] = {}): Directory =
  Directory(
    name: name,
    flags: flags,
    cloud: cloud(name&"/*"),
  )

proc isRoot*(node: DTNode): bool = node.parent.isNil

proc toggle[T](s: var set[T]; v: sink T; b: bool) =
  if b: s.incl v
  else: s.excl v
template toggle_flag(node: DTNode; flag; yes: bool): untyped =
  node.flags.toggle(flag, yes)
  node

proc dummy*[T: DTNode](node: T; yes = true): T =
  toggle_flag(node, dtfDummy, yes)
proc internal*[T: DTNode](node: T; yes = true): T =
  toggle_flag(node, dtfInternal, yes)

proc inherit*[T: DTNode](node: T): T =
  result = node
  node.relationSetting = rsInherit
proc allowImport*[T: DTNode](node: T): T =
  result = node
  node.relationSetting = rsAllowImport
proc allowImportAndExport*[T: DTNode](node: T): T =
  result = node
  node.relationSetting = rsAllowImportAndExport

proc dontExportRequires*(module: Module): Module =
  result = module
  module.exportSetting = esDontExport
proc exportAllowedRequires*(module: Module): Module =
  result = module
  module.exportSetting = esExportAllowed
proc exportAllRequires*(module: Module): Module =
  result = module
  module.exportSetting = esExportAll

proc take*(dir: Directory; modules: varargs[Module]): Directory {.discardable.} =
  result = dir
  for module in modules:
    if module.parent != nil:
      module.parent.modules.del(module.name)
      module.parent.cloud.modules.excl module
    module.parent = dir
    dir.modules[module.name] = module
    if dtfInternal notin module.flags:
      dir.cloud.modules.incl module
proc take*(dir: Directory; subdirs: varargs[Directory]): Directory {.discardable.} =
  result = dir
  for subd in subdirs:
    if subd.parent != nil:
      subd.parent.subdirs.del(subd.name)
      subd.parent.cloud.subClouds.excl subd.cloud
    subd.parent = dir
    dir.subdirs[subd.name] = subd
    if dtfInternal notin subd.flags:
      dir.cloud.subClouds.incl subd.cloud

macro takeBlock*(dir: Directory; stmt): Directory =
  result = dir
  for line in stmt:
    result = ident"take".newCall(result, line)

macro addBlock*(module: Module; stmt): Module =
  let children = stmtList_to_seq(stmt, "$$")
  return quote do:
    (discard `module`.contents.add(children); `module`)

proc rootDir*(node: DTNode): Directory =
  if node.parent == nil:
    when node is Module:
      return nil
    else:
      return Directory(node)
  return node.parent.rootDir

proc absolutePath*(node: DTNode): string =
  if node.parent == nil: return node.nameWithExt
  absolutePath(node.parent)/node.nameWithExt

proc relativePath*(path: DTNode; base: Directory): string =
  if path.rootDir != base.rootDir: return path.absolutePath
  result = "."/relativePath(path.absolutePath, base.absolutePath)

proc relativePath*(path: DTNode; base: Module): string =
  path.relativePath(base.parent)

template path*(node: DTNode): string = node.absolutePath

proc `/`*(dir: Directory; path: string): Directory =
  let pathtokens = path.normalizedPath.split("/")
  result = dir
  for path in pathtokens:
    case path
    of ".": discard
    of "..": result = result.parent
    else:
      result = result.subdirs[path]
proc `//`*(dir: Directory; path: string): Module =
  let pathtokens = path.normalizedPath.split("/")
  var current = dir
  for i, path in pathtokens:
    if i == pathtokens.high:
      return current.modules[path]
    case path
    of ".": discard
    of "..": current = current.parent
    else:
      current = current.subdirs[path]

proc unpackModules*(cloud: Cloud): HashSet[Module] =
  result = cloud.modules
  for sub in cloud.subClouds:
    result.incl unpackModules(sub)

proc getRelation(node: DTNode): RelationSetting =
  if node.relationSetting != rsInherit:
    return node.relationSetting
  if node.isRoot:
    return rsAllowImportAndExport
  return node.parent.getRelation

proc makeImportSentence(target, module: Module; res: var string) : bool =
  let path = target.relativePath(module).changeFileExt("")
  template ie: string = "import " & path & "; export " & target.name
  template i: string = "import " & path
  case target.getRelation
  of rsInherit: return false
  of rsAllowImport:
    case module.exportSetting:
    of esDontExport, esExportAllowed:
      res = i
    of esExportAll:
      res = ie
    return true
  of rsAllowImportAndExport:
    case module.exportSetting:
    of esDontExport:
      res = i
    of esExportAllowed, esExportAll:
      res = ie
    return true

proc importFromCloud*(_:typedesc[ParagraphSt]; module: Module): ParagraphSt =
  var statements: seq[string]
  var str: string
  for target in module.cloud.unpackModules:
    if makeImportSentence(target, module, str):
      statements.add str

  result = ParagraphSt(children: newSeqOfCap[Statement](statements.len))
  for s in statements.sorted:
    result.children.add text s

proc generate*(module: Module) =
  if dtfDummy in module.flags: return
  var statement = +$$..ParagraphSt():
    module.header
    ParagraphSt.importFromCloud(module)
    ""
    module.contents
  module.path.writeFile $statement

proc generate*(dir: Directory) =
  if dtfDummy in dir.flags: return
  var items: seq[string]
  if not dir.path.dirExists:
    createDir dir.path
  for name, subd in dir.subdirs:
    generate subd
    items.add subd.dumpname({dtfDummy})
  for name, module in dir.modules:
    generate module
    items.add module.dumpname({dtfDummy})

  (dir.path/"modulegenInfo.nims").writeFile do:
    "let modules: seq[string] = @[\n" &
    items.mapIt(&"  \"{it}\",\n").join("") &
    "]\n" & modulegenInfo_template

proc drop*(directory: string) =
  let path = directory/"modulegenInfo.nims"
  if fileExists(path):
    discard execShellCmd fmt"nim --hints:off {path}"
proc drop*(directory: Directory) =
  drop(directory.path)

proc dumpTree*(cloud: Cloud; base: Module): Statement =
  let tree = TreeSt(head: cloud.dumpName)
  result = tree

  for module in cloud.modules:
    discard tree.add module.relativePath(base)
  for subc in cloud.subClouds:
    discard tree.add dumpTree(subc, base)

proc dumpTree*(module: Module): Statement =
  let tree = TreeSt(head: module.dumpName)
  result = tree
  discard tree.add dumpTree(module.cloud, module)
proc dumpTree*(module: Directory): Statement =
  let tree = TreeSt(head: module.dumpName)
  result = tree
  for name, subd in module.subdirs:
    discard tree.add dumpTree(subd)
  for name, module in module.modules:
    discard tree.add dumpTree(module)

# Statements extension
# --------------------

type IncludeSt* = ref object of AtomSt
  path*, base*: Module

method render*(self: IncludeSt; cfg: RenderingConfig): seq[string] =
  @["include " & self.path.relativePath(self.base)]

# Sugar
# -----

template `+$$..`*(module: Module; stmt): Module =
  module.addBlock stmt

template `+/%..`*(directory: Directory; stmt): Directory =
  directory.takeBlock stmt