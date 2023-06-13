import logging_core

type
  ConsoleLogger* = ref object of Logger
    useStderr*: bool

method log*(logger: ConsoleLogger, level: Level, args: varargs[string, `$`]) =
  if level >= logger.levelThreshold:
    let ln = substituteLog(logger.fmtStr, level, args)
    try:
      var handle = stdout
      if logger.useStderr:
        handle = stderr
      writeLine(handle, ln)
      if level >= logger.flushThreshold: flushFile(handle)
    except IOError:
      discard

proc newConsoleLogger*(levelThreshold = lvlAll, fmtStr = defaultFmtStr,
    useStderr = false, flushThreshold = defaultFlushThreshold): ConsoleLogger =
  new result
  result.fmtStr = fmtStr
  result.levelThreshold = levelThreshold
  result.flushThreshold = flushThreshold
  result.useStderr = useStderr