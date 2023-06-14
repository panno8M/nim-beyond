import std/strutils
import std/times
import std/os
import std/options

type
  Level* = enum
    lvlAll,
    lvlDebug,
    lvlInfo,
    lvlNotice,
    lvlWarn,
    lvlError,
    lvlFatal,
    lvlNone

const
  LevelNames*: array[Level, string] = [
    "DEBUG", "DEBUG", "INFO", "NOTICE", "WARN", "ERROR", "FATAL", "NONE"
  ]

  defaultFmtStr* = "$levelname "
  verboseFmtStr* = "$levelid, [$datetime] -- $appname: "
  defaultFlushThreshold* = when NimMajor >= 2:
      when defined(nimV1LogFlushBehavior): lvlError else: lvlAll
    else:
      when defined(nimFlushAllLogs): lvlAll else: lvlError

type
  Logger* = ref object of RootObj
    levelThreshold*: Level
    flushThreshold*: Level
    fmtStr*: string

  LogInfo* = object of RootObj
    level*: Level

method parseToken(info: LogInfo; token: string): Option[string] {.gcsafe, base.} =
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
  else:
    none string

method log*(logger: Logger; info: LogInfo; args: varargs[string, `$`]) {.gcsafe, tags: [RootEffect], base.} =
  discard

type SymbolKind = enum
  skText
  skToken
iterator lex(frmt: string): tuple[symbol: string, kind: SymbolKind] =
  var i = 0
  while i < frmt.len:
    var symbol = ""
    if frmt[i] == '$':
      inc(i)
      while i < frmt.len and frmt[i] in IdentChars:
        symbol.add(toLowerAscii(frmt[i]))
        inc(i)
      yield (symbol, skToken)
    else:
      while i < frmt.len and frmt[i] != '$':
        symbol.add frmt[i]
        inc(i)
      yield (symbol, skText)

proc substituteLog*(info: LogInfo; frmt: string;
                    args: varargs[string, `$`]): string =
  var msgLen = 0
  for arg in args:
    msgLen += arg.len
  result = newStringOfCap(frmt.len + msgLen + 20)
  for symbol, kind in frmt.lex:
    case kind
    of skText:
      result.add symbol
    of skToken:
      let token = info.parseToken(symbol)
      if token.isSome:
        result.add (get token)
  for arg in args:
    result.add(arg)

proc lazyNew*[T: Logger](self: var T): var T {.inline.} =
  if self.isNil: self = new T
  self