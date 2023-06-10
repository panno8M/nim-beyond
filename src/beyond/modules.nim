import std/[
  sequtils,
  strutils,
  strformat,
  tables,
  macros,
  os,
]
import ./statements

type ModuleKind* {.pure.} = enum
  mkPackage
  mkModule
type Module* = ref object
  name*: string
  header*: string = "## This module is generated automatically."
  parent*: Module
  touchMe*: bool
  exportMe*: bool
  case kind*: ModuleKind
  of mkPackage:
    submodules*: Table[string, Module]
    exportSubmodules*: bool
  of mkModule:
    imports*: seq[Module]
    contents*: Statement = paragraph()


proc module*(_: typedesc[Module]; name: string): Module = Module(name: name, kind: mkModule, touchMe: true, exportMe: true)
proc package*(_: typedesc[Module]; name: string): Module = Module(name: name, kind: mkPackage, touchMe: true, exportMe: true)

proc dontTouch*(module: Module; `y/n` = true): Module {.discardable.} =
  module.touchMe = not `y/n`
  return module

proc dontExport*(module: Module; `y/n` = true): Module {.discardable.} =
  module.exportMe = not `y/n`
  return module

proc takeSubmodules*(pkg: Module; submodules: varargs[Module]): Module {.discardable.} =
  assert pkg.kind == mkPackage
  for submodule in submodules:
    if submodule.parent != nil:
      submodule.parent.submodules.del(submodule.name)
    submodule.parent = pkg

  for submodule in submodules:
    pkg.submodules[submodule.name] = submodule

  return pkg

proc importModules*(module: Module; modules: varargs[Module]): Module {.discardable.} =
  assert module.kind == mkModule
  module.imports.add modules
  return module

proc absoluteModuleChain*(module: Module): seq[Module] =
  if module.parent == nil: return @[module]
  absoluteModuleChain(module.parent).concat(@[module])
proc absolutePath*(module: Module): string =
  absoluteModuleChain(module).mapIt(it.name).join("/")

proc relativePath*(`from`, `to`: Module): string =
  var
    fromChains = absoluteModuleChain(`from`)
    toChains = absoluteModuleChain(`to`)
  if fromChains[0] != toChains[0]:
    return toChains.mapIt(it.name).join("/")
  fromChains.delete(fromChains.high)
  while fromChains.len > 0 and toChains.len > 0 and fromChains[0] == toChains[0]:
      fromChains.delete(0)
      toChains.delete(0)
  concat(
    fromChains.mapIt(".."),
    if toChains.len == 0:
      @["..", `to`.name]
    else:
      toChains.mapIt(it.name)
  ).join("/")

proc path*(module: Module): string = absolutePath(module)
proc pathFrom*(module, `from`: Module): string = relativePath(`from`, module)
func fileName*(module: Module): string = module.path & ".nim"

proc `[]`*(module: Module; path: string): Module =
  case path
  of ".": return module
  of "..": return module.parent
  else: return module.submodules[path]

proc `/`*(module: Module; sub: string): Module = module[sub]

proc exportModule*(module: Module) =
  template exportStatement(body): untyped =
    let file = open(module.fileName, fmWrite)
    defer: close file
    var statement {.inject.} = `paragraph/`:
      module.header
    body
    file.write $statement

  case module.kind

  of mkModule:
    if not module.touchMe: return
    exportStatement:
      for ipt in module.imports:
        discard statement.add "import "&ipt.pathFrom(module)
      discard statement.addBlock:
        ""
        module.contents

  of mkPackage:
    if not module.touchMe: return
    if not module.path.dirExists:
      createDir module.path
    for name, sub in module.submodules:
      exportModule sub

    exportStatement:
      for name, sub in module.submodules:
        if not sub.exportMe: continue
        discard statement.add fmt"import {module.name}/{name}; export {name}"

proc dropModule*(module: Module) =

  case module.kind
  of mkModule:
    if not module.touchMe: return
    discard tryRemoveFile module.fileName
  of mkPackage:
    for name, sub in module.submodules:
      if not sub.exportMe: continue
      dropModule sub

    if not module.touchMe: return
    discard tryRemoveFile module.fileName
    if walkDirs(module.path).toSeq.len == 0:
      removeDir module.path

func dumpName(module: Module): string =
  result = module.name
  if module.exportMe: result &= "*"
  if module.touchMe: result = "[" & result & "]"
  if module.kind == mkPackage: result &= "/"

proc dumpTree*(module: Module): Statement =
  case module.kind
  of mkPackage:
    let subs = paragraph()
    for name, sub in module.submodules:
      discard subs.add dumpTree(sub)
    return `paragraph/`:
      module.dumpName
      indent(2): subs
  of mkModule:
    var imports = module.imports.mapIt it.dumpName
    return `paragraph/`:
      module.dumpName
      `option/`(imports.len != 0):
        "import: " & imports.join(", ")