import std/[
  strformat
]
import ./macros

type BehaviorsIfUnimplemented* = enum
  Raise = "raise"
  Discard = "discard"
  LogWarn = "logWarn"
const BehaviorIfUnimplemented* {.strdefine.} = $BehaviorsIfUnimplemented.Discard

when BehaviorIfUnimplemented == $BehaviorsIfUnimplemented.LogWarn:
  import std/logging; export logging

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
    def[6] =
      case BehaviorIfUnimplemented
      of $BehaviorsIfUnimplemented.Discard:
        quote do: discard
      of $BehaviorsIfUnimplemented.Raise:
        quote do: raise UnimplementedDefect.newException(`errorlit`)
      of $BehaviorsIfUnimplemented.LogWarn:
        quote do: warn `errorlit`
      else:
        quote do: discard
  else: 
    warning &"Unexpected expression has been caught; leave as it is.\n{def.lisprepr}", def
  return def

when isMainModule:
  proc someproc1(): void {.unimplemented, used.} = echo "hello"
  proc someproc2(): void {.unimplemented, used.}
  func somefunc(): void {.unimplemented, used.}