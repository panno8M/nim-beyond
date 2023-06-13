import logging_core

type
  LoggerGroup* = ref object of Logger
    loggers*: seq[Logger]

method log*(logger: LoggerGroup, level: Level, args: varargs[string, `$`]) =
  if level >= logger.levelThreshold:
    for each in logger.loggers:
      each.log(level, args)
