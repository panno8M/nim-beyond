import std/[
  strformat
]
import beyond/[
  macros
]

const RaiseRuntimeErrorIfUnimplemented* {.booldefine.} = false
type UnimplementedDefect* = object of Defect

macro unimplemented*(def): untyped =
  case def.kind
  of nnkProcDef, nnkFuncDef:
    let procdefref = copy def
    procdefref[6] = newEmptyNode()
    let errormsg =
      if def[6].kind == nnkEmpty:
        &"`{repr procDefref}` has not been implemented yet"
      else:
        &"`{repr procDefref}` describes the process, but it is considered unimplemented"
    let errorlit = newLit errormsg
    warning errormsg, def
    def[6] = quote do:
      when RaiseRuntimeErrorIfUnimplemented:
        raise UnimplementedDefect.newException(`errorlit`)
      else:
        discard
  else: 
    warning &"Unexpected expression has been caught; leave as it is.\n{def.lisprepr}", def
  return def

when isMainModule:
  proc someproc1(): void {.unimplemented, used.} = echo "hello"
  proc someproc2(): void {.unimplemented, used.}
  func somefunc(): void {.unimplemented, used.}