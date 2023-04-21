import std/[
  strformat,
]
import beyond/[
  macros
]

proc statics_proc(Type,node: NimNode): seq[NimNode] =
  node.expectKind nnkProcDef
  let basename = node[0].getname
  let classname = nnkAccQuoted.newTree(ident &"{Type}.{basename}")
  let funcname = basename.exportIf(node[0].isExported)
  node[0] = node[0].setName(classname)
  result.add quote do:
    template `funcname`(_: typedesc[`Type`]; args: varargs[untyped]): untyped {.used.} = `classname`(args)

proc statics_var(Type,node: NimNode): seq[NimNode] =
  let basename = node[0].getname
  let expt = node[0].isExported
  let classname = nnkAccQuoted.newTree(ident &"{Type}.{basename}")
  node[0] = node[0].setName(classname)

  let setter = nnkAccQuoted.newTree(ident &"{basename}=").exportIf(expt)
  let getter = nnkAccQuoted.newTree(ident &"{basename}").exportIf(expt)
  result.add quote do:
    template `setter`(_: typedesc[`Type`]; args: varargs[untyped]): untyped {.used.} = `classname` = args
  result.add quote do:
    template `getter`(_: typedesc[`Type`]): untyped {.used.} = `classname`


macro statics*[T](Type: typedesc[T]; body): untyped =
  template warn(node: NimNode) = warning &"we do not have feature to convert this section to object-static:\n{node.lisprepr}", node
  for node in body:
    case node.kind
    of nnkVarSection:
      for def in node:
        case def.kind:
        of nnkIdentDefs:
          body.add statics_var(Type, def)
        else:
          warn nnkVarSection.newTree def
    
    of nnkProcDef:
      body.add statics_proc(Type, node)
    else:
      warn node
  body

when isMainModule:
  int.statics:
    var a*: int = 2
    var `b`*: int = 2
    proc initialize*(lvl: int) {.nimcall.} =
      discard
    proc `deinitialize`(lvl: int) =
      discard
    type c = enum
      d, e

  int.a = 1
  int.b = 1
  int.initialize(0)