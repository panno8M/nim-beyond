import beyond/logging
import beyond/oop
import std/strutils
import std/strformat

proc format {.implement: LogFormat.} = &"{levelname} {args.join()}"
proc verbose {.implement: LogFormat.} = &"{levelid}, {levelname} -- {appname}: {args.join()}"

var L = newConsoleLogger(format= format)
var fL = newFileLogger("test.log", format= verbose)
var rL = newRollingFileLogger("rolling.log", format = verbose)

defaultGroup.loggers.add(@[fL, rL, L])
for i in 0 .. 5:
  info "hello", i

var nilString: string
info "hello", nilString