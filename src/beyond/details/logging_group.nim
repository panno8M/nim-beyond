import logging_core

type
  LoggerGroup* = ref object of Logger
    loggers*: seq[Logger]

method log*(logger: LoggerGroup, info: LogInfo, args: varargs[string, `$`]) =
  if info.level >= logger.levelThreshold:
    for each in logger.loggers:
      each.log(info, args)
