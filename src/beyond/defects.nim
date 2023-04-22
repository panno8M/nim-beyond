import std/[
  strformat
]
import beyond/[
  macros
]

type UnimplementedDefect* = object of Defect

macro unimplemented*(def): untyped =
  case def.kind:
  of nnkProcDef, nnkFuncDef:
    let errormsg =
      if def[6].kind == nnkEmpty:
        &"`{def[0].getname}` has not been implemented yet"
      else:
        &"`{def[0].getname}` describes the process, but it is considered unimplemented"
    let errorlit = newStrLitNode errormsg
    warning errormsg, def
    def[6] = newNimNode(nnkStmtList)
              .add(quote do:
                raise UnimplementedDefect.newexception(`errorlit`))
  else: 
    warning &"Unexpected expression has been caught; leave as it is.\n{def.lisprepr}", def
  return def

when isMainModule:
  proc someproc1(): void {.unimplemented, used.} = echo "hello"
  proc someproc2(): void {.unimplemented, used.}
  func somefunc(): void {.unimplemented, used.}