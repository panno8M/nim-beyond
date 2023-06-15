import std/strutils

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

  LogData* = object of RootObj

method log*(logger: Logger; level: Level; data: LogData; args: varargs[string, `$`]) {.gcsafe, tags: [RootEffect], base.} = discard

type SymbolKind = enum
  skText
  skToken
iterator lex*(frmt: string): tuple[symbol: string, kind: SymbolKind] =
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

method parse*(data: LogData; level: Level; frmt: string;
                    args: varargs[string, `$`]): string {.gcsafe,base.} =
  var msgLen = 0
  for arg in args:
    msgLen += arg.len
  result = newStringOfCap(frmt.len + msgLen)
  result.add frmt
  for arg in args:
    result.add arg

proc lazyNew*[T: Logger](self: var T): var T {.inline.} =
  if self.isNil: self = new T
  self