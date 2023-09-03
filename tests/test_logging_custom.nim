import beyond/[
  logging_api, logging_formatshelf,
  oop,
  ]

import std/os
import std/times
import std/strformat
import std/strutils
import std/sequtils

type
  Stage* = enum
    stgEngine  = "ENGINE"
    stgLibrary = "LIBRARY"
    stgUser    = "USER"
  LogUser* = object
    stage*: Stage
    handler*: string
  MyLogData* = object of LogData
    p_user*: ptr LogUser
    summary*: string
    frame*: PFrame

template stage: string = $data.p_user.stage
template handler: string = $data.p_user.handler
template summary: string = $data.summary
proc format {.implement: LogFormat.} =
  let data = MyLogData data
  fmt "[{data.frame.procname}: {data.frame.filename}({data.frame.line})] {levelname}-{stage} @{handler} >>> {summary}\n{args.join().splitLines.mapIt(\"  :: \"&it).join()}"

var L = newConsoleLogger(format= format)
var fL = newFileLogger("test.log", format= format)
var rL = newRollingFileLogger("rolling.log", format = format)

defaultGroup.loggers.add(@[fL, rL, L])

block:
  let me = LogUser(handler: "for-loop", stage: stgUser)
  var data = MyLogData(p_user: addr me, level: lvlInfo, frame: getFrame())
  for i in 0 .. 5:
    data.summary = &"HELLO-{i}"
    # data.frame = getFrame()
    data.log("hello, my-logging! ", i)

block:
  var nilString: string
  var me = LogUser(handler: "single-call", stage: stgUser)
  let data = MyLogData(p_user: addr me, summary: "HELLO", level: lvlInfo, frame: getFrame())
  data.log("hello", nilString)