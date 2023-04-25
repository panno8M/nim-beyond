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
  mkSingle
type Module* = ref object
  name*: string
  header*: string = "## This module is generated automatically."
  parent*: Module
  case kind*: ModuleKind
  of mkPackage:
    submodules*: Table[string, Module]
    exportSubmodules*: bool
  of mkSingle:
    imports*: seq[Module]
    contents* = Statement.dummy


proc dummy*(_: typedesc[Module]; name: string): Module = Module(name: name, kind: mkSingle)
proc dummyPkg*(_: typedesc[Module]; name: string): Module = Module(name: name, kind: mkPackage)

proc add*(pkg: Module; submodules: varargs[Module]): Module {.discardable.} =
  assert pkg.kind == mkPackage
  for submodule in submodules:
    if submodule.parent != nil:
      submodule.parent.submodules.del(submodule.name)
    submodule.parent = pkg

  for submodule in submodules:
    pkg.submodules[submodule.name] = submodule

  return pkg

proc importModule*(module: Module; submodules: varargs[Module]): Module {.discardable.} =
  assert module.kind == mkSingle
  module.imports.add submodules
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
  var file = open(fmt"{module.path}.nim", fmWrite)
  defer: close file

  case module.kind

  of mkSingle:
    var stmt = Statement.dummy
      .add(Statement.sentence(module.header))
      .add(module.imports.mapIt Statement.sentence fmt"import {it.pathFrom(module)}")
      .add(Statement.blank)
      .add(module.contents)
    file.write $stmt

  of mkPackage:
    var stmt = Statement.dummy
      .add(Statement.sentence(module.header))
    for name, sub in module.submodules:
      stmt.add Statement.sentence fmt"import {module.name}/{name}; export {name}"
    file.write $stmt
    if not module.path.dirExists:
      createDir module.path
    for name, sub in module.submodules:
      exportModule sub

proc dumpTree*(module: Module): Statement =
  case module.kind
  of mkPackage:
    result = Statement.header fmt"{module.name}/"
    for name, sub in module.submodules:
      result.add dumpTree(sub)
  of mkSingle:
    result = Statement.sentence module.name
