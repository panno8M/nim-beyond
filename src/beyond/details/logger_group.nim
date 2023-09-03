import logging_core

type
  LoggerGroup* = ref object of Logger
    loggers*: seq[Logger]

method log*(logger: LoggerGroup; data: LogData, args: varargs[string, `$`]) =
  if data.level >= logger.levelThreshold:
    for each in logger.loggers:
      each.log(data, args)
