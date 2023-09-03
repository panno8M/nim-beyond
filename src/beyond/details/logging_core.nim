type
  Level* = enum
    lvlAll = "DEBUG",
    lvlDebug = "DEBUG",
    lvlInfo = "INFO",
    lvlNotice = "NOTICE",
    lvlWarn = "WARN",
    lvlError = "ERROR",
    lvlFatal = "FATAL",
    lvlNone = "NONE"

const
  defaultFlushThreshold* = when NimMajor >= 2:
      when defined(nimV1LogFlushBehavior): lvlError else: lvlAll
    else:
      when defined(nimFlushAllLogs): lvlAll else: lvlError

type
  LogData* {.byref.} = object of RootObj
    level*: Level
  LogFormat* = proc(data: LogData; args: seq[string]): string {.gcsafe.}

type
  Logger* = ref object of RootObj
    levelThreshold*: Level
    flushThreshold*: Level
    format*: LogFormat

method log*(logger: Logger; data: LogData; args: varargs[string, `$`]) {.gcsafe, tags: [RootEffect], base.} = discard

proc lazyNew*[T: Logger](self: var T): var T {.inline.} =
  if unlikely(self.isNil): self = new T
  self