import std/[
  sequtils,
  strutils,
  strformat,
  tables,
  macros,
  os,
]
import statements

type ModuleKind* {.pure.} = enum
  mkPackage
  mkModule
type Module* = ref object
  name*: string
  header*: string = "## This module is generated automatically."
  parent*: Module
  createMe*: bool
  exportMe*: bool
  case kind*: ModuleKind
  of mkPackage:
    submodules*: Table[string, Module]
    exportSubmodules*: bool
  of mkModule:
    imports*: seq[Module]
    contents* = Statement.dummy


proc module*(_: typedesc[Module]; name: string): Module = Module(name: name, kind: mkModule, createMe: true, exportMe: true)
proc package*(_: typedesc[Module]; name: string): Module = Module(name: name, kind: mkPackage, createMe: true, exportMe: true)

proc dontCreate*(module: Module; `y/n` = true): Module {.discardable.} =
  module.createMe = not `y/n`
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

proc `contents=`*(module: Module; contents: Statement): Module {.discardable.} =
  assert module.kind == mkModule
  module.contents = contents
  return module
proc addContents*(module: Module; contents: Statement): Module {.discardable.} =
  assert module.kind == mkModule
  module.contents.add contents
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

template path*(module: Module): string = absolutePath(module)
template pathFrom*(module, `from`: Module): string = relativePath(`from`, module)
func fileName*(module: Module): string = module.path & ".nim"

proc `[]`*(module: Module; path: string): Module =
  case path
  of ".": return module
  of "..": return module.parent
  else: return module.submodules[path]

macro `/`*(module: Module; path: untyped): Module =
  let strlit = newStrLitNode($path)
  quote do:
    `module`[`strlit`]

proc exportModule*(module: Module) =
  template exportStatement(body): untyped =
    let file = open(module.fileName, fmWrite)
    defer: close file
    var statement {.inject.} = Statement.dummy
      .add(Statement.sentence(module.header))
    body
    file.write $statement

  case module.kind

  of mkModule:
    if not module.createMe: return
    exportStatement:
      statement
        .add(module.imports.mapIt Statement.sentence fmt"import {it.pathFrom(module)}")
        .add(Statement.blank)
        .add(module.contents)

  of mkPackage:
    if not module.createMe: return
    if not module.path.dirExists:
      createDir module.path
    for name, sub in module.submodules:
      exportModule sub

    exportStatement:
      for name, sub in module.submodules:
        if not sub.exportMe: continue
        statement.add Statement.sentence fmt"import {module.name}/{name}; export {name}"

proc dropModule*(module: Module) =

  case module.kind
  of mkModule:
    if not module.createMe: return
    discard tryRemoveFile module.fileName
  of mkPackage:
    for name, sub in module.submodules:
      if not sub.exportMe: continue
      dropModule sub

    if not module.createMe: return
    discard tryRemoveFile module.fileName
    if walkDirs(module.path).toSeq.len == 0:
      removeDir module.path

func dumpName(module: Module): string =
  result = module.name
  if module.exportMe: result &= "*"
  if module.createMe: result = "[" & result & "]"
  if module.kind == mkPackage: result &= "/"

proc dumpTree*(module: Module): Statement =
  case module.kind
  of mkPackage:
    result = Statement.header module.dumpName
    for name, sub in module.submodules:
      result.add dumpTree(sub)
  of mkModule:
    result = Statement.header module.dumpName
    var imports = module.imports.mapIt it.dumpName
    if imports.len != 0:
      result.add Statement.sentence "import: " & imports.join(", ")
