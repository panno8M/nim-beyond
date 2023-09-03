import logging_core

type
  ConsoleLogger* = ref object of Logger
    useStderr*: bool

method log*(logger: ConsoleLogger; data: LogData; args: varargs[string, `$`]) {.gcsafe.} =
  if data.level >= logger.levelThreshold:
    let ln = logger.format(data, @args)
    try:
      var handle = stdout
      if logger.useStderr:
        handle = stderr
      writeLine(handle, ln)
      if data.level >= logger.flushThreshold: flushFile(handle)
    except IOError:
      discard

proc newConsoleLogger*(levelThreshold = lvlAll, format: LogFormat,
    useStderr = false, flushThreshold = defaultFlushThreshold): ConsoleLogger =
  new result
  result.format = format
  result.levelThreshold = levelThreshold
  result.flushThreshold = flushThreshold
  result.useStderr = useStderr