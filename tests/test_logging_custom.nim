import beyond/logging_api

import std/os
import std/times
import std/strutils

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

proc parseToken(data: MyLogData; level: Level; token: string; res: var string): bool {.gcsafe.} =
  let app = getAppFilename()
  case token
  of "date"     : res= getDateStr()
  of "time"     : res= getClockStr()
  of "datetime" : res= getDateStr() & "T" & getClockStr()
  of "app"      : res= app
  of "appdir"   : res= app.splitFile.dir
  of "appname"  : res= app.splitFile.name
  of "levelid"  : res= $LevelNames[level][0]
  of "levelname": res= LevelNames[level]
  of "stage"    : res= $data.p_user.stage
  of "summary"  : res= data.summary
  of "handler"  : res= data.p_user.handler
  else:
    return false
  return true

const myFormat = "$levelname-$stage @$handler >>> $summary"

method parse*(data: MyLogData; level: Level; frmt: string;
                    args: varargs[string, `$`]): string {.gcsafe.} =
  var msgLen = 0
  for arg in args:
    msgLen += arg.len
  result = newStringOfCap(frmt.len + data.summary.len + msgLen + 20)
  var token: string
  for symbol, kind in frmt.lex:
    case kind
    of skText:
      result.add symbol
    of skToken:
      if data.parseToken(level, symbol, token):
        result.add token
      else:
        result.add "$"&symbol
  result.add "\n"
  for line in args.join("").splitLines:
    result.add " :: " & line

var L = newConsoleLogger(fmtStr = myFormat)
var fL = newFileLogger("test.log", fmtStr = myFormat)
var rL = newRollingFileLogger("rolling.log", fmtStr = myFormat)

defaultGroup.loggers.add(@[fL, rL, L])

block:
  let me = LogUser(handler: "for-loop", stage: stgUser)
  for i in 0 .. 5:
    MyLogData(p_user: unsafeAddr me, summary: "HELLO-" & $i).info("hello, my-logging! ", i)

block:
  var nilString: string
  var me = LogUser(handler: "single-call", stage: stgUser)
  MyLogData(p_user: unsafeAddr me, summary: "HELLO").info("hello", nilString)