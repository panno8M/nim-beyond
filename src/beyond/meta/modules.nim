import std/[
  sequtils,
  strutils,
  strformat,
  tables,
  sets,
  hashes,
  os,
]
import ./statements
import ../macros

const modulegenInfo_template = staticRead("./beyond/meta/modules/modulegenInfo_template.nims")

proc hash*[T](x: ref[T]): Hash {.inline.} =
  hash(cast[pointer](x))

type
  DTFlag* = enum
    dtfDummy
    dtfIncludee
template All*(_: typedesc[set[DTFlag]]): set[DTFlag] =
  {dtfDummy, dtfIncludee}
type
  DTNode* = Directory or Module ## Directory-Tree Node
  ExportLevel* = enum
    esPrivate           = -2
    esRecommendPrivate  = -1
    esInherit           =  0
    esFriend            =  1
    esPublic            =  2

  Cloud* = ref object
    name*: string
    subClouds*: HashSet[Cloud]
    modules*: HashSet[Module]
    directories*: HashSet[Directory]

  Directory* = ref object
    name*: string
    exportLevel*: ExportLevel = esInherit
    flags*: set[DTFlag]
    parent*: Directory
    modules*: Table[string, Module]
    subdirs*: Table[string, Directory]

  Module* = ref object
    name*: string
    exportLevel*: ExportLevel = esInherit
    exportThrethold*: ExportLevel = esPublic
    flags*: set[DTFlag]
    parent*: Directory
    cloud*: Cloud
    contents*: Statement = ParagraphSt()
    header*: string = "## This module was generated automatically. Changes will be lost."

const moduleExt*: string = ".nim"
template nameWithExt*(module: Module): string = module.name & moduleExt
template nameWithExt*(module: Directory): string = module.name

func dumpName(cloud: Cloud): string =
  var name = cloud.name
  if name.isEmptyOrWhitespace:
    name = "cloud_@" & cast[uint64](cloud).toHex()
  result = "{{" & name & "}}"

func dumpName(module: Module; mask = set[DTFlag].All): string =
  result = module.nameWithExt
  let masked = mask * module.flags
  if dtfDummy in masked: result = "[" & result & "]"

func dumpName(directory: Directory; mask = set[DTFlag].All): string =
  result = directory.name & "/"
  let masked = mask * directory.flags
  if dtfDummy in masked: result = "[" & result & "]"

proc unpackModules*(dir: Directory; depth = Natural.high): HashSet[Module] =
  if depth == 0: return
  for name, module in dir.modules:
    result.incl module
  for name, subd in dir.subdirs:
    result.incl subd.unpackModules(depth.pred)

proc incl*[T](s: var HashSet[T]; items: varargs[T]) =
  s.incl toHashSet @items
proc inclModules*(cloud: Cloud; modules: HashSet[Module]|Module): Cloud =
  result = cloud; result.modules.incl modules
proc inclDirs*(cloud: Cloud; directories: HashSet[Directory]|Directory): Cloud =
  result = cloud; result.directories.incl directories
proc inclClouds*(cloud: Cloud; subclouds: HashSet[Cloud]|Cloud): Cloud =
  result = cloud; cloud.subClouds.incl subclouds

proc inclModules*(module: Module; modules: HashSet[Module]|Module): Module =
  result = module; discard module.cloud.inclModules modules
proc inclDirs*(module: Module; directories: HashSet[Directory]|Directory): Module =
  result = module; discard module.cloud.inclDirs directories
proc inclClouds*(module: Module; clouds: HashSet[Cloud]|Cloud): Module =
  result = module; discard module.cloud.inclClouds clouds

proc inclModules*(cloud: Cloud; modules: varargs[Module]): Cloud =
  result = cloud; result.modules.incl modules
proc inclDirs*(cloud: Cloud; directories: varargs[Directory]): Cloud =
  result = cloud; result.directories.incl directories
proc inclClouds*(cloud: Cloud; subclouds: varargs[Cloud]): Cloud =
  result = cloud; cloud.subClouds.incl subclouds

proc inclModules*(module: Module; modules: varargs[Module]): Module =
  result = module; discard module.cloud.inclModules modules
proc inclDirs*(module: Module; directories: varargs[Directory]): Module =
  result = module; discard module.cloud.inclDirs directories
proc inclClouds*(module: Module; clouds: varargs[Cloud]): Module =
  result = module; discard module.cloud.inclClouds clouds

proc cloud*(name: string): Cloud =
  Cloud(name: name)

proc mdl*(name: string; flags: set[DTFlag] = {}): Module = Module(name: name, flags: flags, cloud: cloud(name&"_cloud"))
proc dir*(name: string; flags: set[DTFlag] = {}): Directory = Directory(name: name, flags: flags)

proc isRoot*(node: Module|Directory): bool = node.parent.isNil

proc toggle[T](s: var set[T]; v: sink T; b: bool) =
  if b: s.incl v
  else: s.excl v
template toggle_flag(node: DTNode; flag; yes: bool): untyped =
  node.flags.toggle(flag, yes)
  node

proc dummy*[T: DTNode](node: T; yes = true): T =
  toggle_flag(node, dtfDummy, yes)
proc includee*[T: DTNode](node: T; yes = true): T =
  toggle_flag(node, dtfIncludee, yes)

proc private*[T: DTNode](node: T): T =
  result = node
  node.exportLevel = esPrivate
proc recommendPrivate*[T: DTNode](node: T): T =
  result = node
  node.exportLevel = esRecommendPrivate
proc inherit*[T: DTNode](node: T): T =
  result = node
  node.exportLevel = esInherit
proc friend*[T: DTNode](node: T): T =
  result = node
  node.exportLevel = esFriend
proc public*[T: DTNode](node: T): T =
  result = node
  node.exportLevel = esPublic

proc setExport*(module: Module; threthold: ExportLevel): Module =
  result = module; result.exportThrethold = threthold

proc take*(dir: Directory; modules: varargs[Module]): Directory {.discardable.} =
  result = dir
  for module in modules:
    if module.parent != nil:
      module.parent.modules.del(module.name)
    module.parent = dir
    dir.modules[module.name] = module
proc take*(dir: Directory; subdirs: varargs[Directory]): Directory {.discardable.} =
  result = dir
  for subd in subdirs:
    if subd.parent != nil:
      subd.parent.subdirs.del(subd.name)
    subd.parent = dir
    dir.subdirs[subd.name] = subd

macro takeBlock*(dir: Directory; stmt): Directory =
  result = dir
  for line in stmt:
    result = ident"take".newCall(result, line)

macro addBlock*(module: Module; stmt): Module =
  let children = stmtList_to_seq(stmt, "$$")
  return quote do:
    (discard `module`.contents.add(children); `module`)


proc absolutePath*(node: DTNode): string =
  if node.parent == nil: return node.nameWithExt
  absolutePath(node.parent)/node.nameWithExt

proc relativePath*(path: DTNode; base: Directory): string =
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
  for directory in cloud.directories:
    result.incl unpackModules(directory)
  for sub in cloud.subClouds:
    result.incl unpackModules(sub)

proc getExportLevel(node: DTNode): ExportLevel =
  if node.exportLevel == esInherit:
    if node.isRoot:
      return esFriend
    return node.parent.getExportLevel
  return node.exportLevel
proc makeImportSentence(target, module: Module; res: var string) : bool =
  if dtfIncludee in target.flags: return false
  let path = target.relativePath(module).changeFileExt("")
  if target.getExportLevel >= module.exportThrethold:
    res = "import " & path & "; export " & target.name
    return true
  else:
    res = "import " & path
    return true

proc importFromCloud*(_:typedesc[ParagraphSt]; module: Module): ParagraphSt =
  result = ParagraphSt()
  var str: string
  for target in module.cloud.unpackModules:
    if makeImportSentence(target, module, str):
      discard result.add str

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

  for directory in cloud.directories:
    discard tree.add directory.relativePath(base) & "/ ..."
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