import beyond/logging

import std/options
import std/os
import std/times

type
  Stage* = enum
    stgEngine  = "ENGINE"
    stgLibrary = "LIBRARY"
    stgUser    = "USER"
  MyLogInfo* = object of LogInfo
    stage*: Stage

method parseToken(info: MyLogInfo; token: string): Option[string] {.gcsafe.} =
  let app = getAppFilename()
  case token
  of "date": some getDateStr()
  of "time": some getClockStr()
  of "datetime": some getDateStr() & "T" & getClockStr()
  of "app": some app
  of "appdir": some app.splitFile.dir
  of "appname": some app.splitFile.name
  of "levelid": some $LevelNames[info.level][0]
  of "levelname": some LevelNames[info.level]
  of "stage": some $info.stage
  else:
    none string

var L = newConsoleLogger(fmtStr = "$levelname - $stage : ")
var fL = newFileLogger("test.log", fmtStr = verboseFmtStr)
var rL = newRollingFileLogger("rolling.log", fmtStr = verboseFmtStr)

var group = LoggerGroup(loggers: @[fL, rL, L])
for i in 0 .. 25:
  group.log(MyLogInfo(level: lvlInfo, stage: stgUser),"hello", i)

var nilString: string
group.log(MyLogInfo(level: lvlInfo, stage: stgUser),"hello", nilString)