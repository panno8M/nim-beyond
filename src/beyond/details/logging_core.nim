import std/strutils
import std/times
import std/os

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

method log*(logger: Logger, level: Level, args: varargs[string, `$`]) {.gcsafe, tags: [RootEffect], base.} =
  discard

proc substituteLog*(frmt: string, level: Level,
                    args: varargs[string, `$`]): string =
  var msgLen = 0
  for arg in args:
    msgLen += arg.len
  result = newStringOfCap(frmt.len + msgLen + 20)
  var i = 0
  while i < frmt.len:
    if frmt[i] != '$':
      result.add(frmt[i])
      inc(i)
    else:
      inc(i)
      var v = ""
      let app = getAppFilename()
      while i < frmt.len and frmt[i] in IdentChars:
        v.add(toLowerAscii(frmt[i]))
        inc(i)
      case v
      of "date": result.add(getDateStr())
      of "time": result.add(getClockStr())
      of "datetime": result.add(getDateStr() & "T" & getClockStr())
      of "app": result.add(app)
      of "appdir": result.add(app.splitFile.dir)
      of "appname": result.add(app.splitFile.name)
      of "levelid": result.add(LevelNames[level][0])
      of "levelname": result.add(LevelNames[level])
      else: discard
  for arg in args:
    result.add(arg)

proc lazyNew*[T: Logger](self: var T): var T {.inline.} =
  if self.isNil: self = new T
  self