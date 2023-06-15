## logging API with nim-standard implementation

import logging_api; export logging_api

import std/times
import std/os

type NimLogData* = object of LogData

proc parseToken(data: NimLogData; level: Level; token: string; res: var string): bool {.gcsafe.} =
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
  else:
    return false
  return true

method parse*(data: NimLogData; level: Level; frmt: string;
                    args: varargs[string, `$`]): string {.gcsafe.} =
  var msgLen = 0
  for arg in args:
    msgLen += arg.len
  result = newStringOfCap(frmt.len + msgLen + 20)
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
  for arg in args:
    result.add(arg)

template debug  *(args: varargs[string, `$`]) = defaultGroup.log(lvlDebug, NimLogData(), args)
template info   *(args: varargs[string, `$`]) = defaultGroup.log(lvlInfo, NimLogData(), args)
template notice *(args: varargs[string, `$`]) = defaultGroup.log(lvlNotice, NimLogData(), args)
template warn   *(args: varargs[string, `$`]) = defaultGroup.log(lvlWarn, NimLogData(), args)
template error  *(args: varargs[string, `$`]) = defaultGroup.log(lvlError, NimLogData(), args)
template fatal  *(args: varargs[string, `$`]) = defaultGroup.log(lvlFatal, NimLogData(), args)