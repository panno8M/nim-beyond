import logging_core

type
  ConsoleLogger* = ref object of Logger
    useStderr*: bool

method log*(logger: ConsoleLogger; info: LogInfo; args: varargs[string, `$`]) {.gcsafe.} =
  if info.level >= logger.levelThreshold:
    let ln = info.substituteLog(logger.fmtStr, args)
    try:
      var handle = stdout
      if logger.useStderr:
        handle = stderr
      writeLine(handle, ln)
      if info.level >= logger.flushThreshold: flushFile(handle)
    except IOError:
      discard

proc newConsoleLogger*(levelThreshold = lvlAll, fmtStr = defaultFmtStr,
    useStderr = false, flushThreshold = defaultFlushThreshold): ConsoleLogger =
  new result
  result.fmtStr = fmtStr
  result.levelThreshold = levelThreshold
  result.flushThreshold = flushThreshold
  result.useStderr = useStderr