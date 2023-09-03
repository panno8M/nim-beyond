import details/logging_core;   export logging_core

import details/logger_console; export logger_console
import details/logger_file;    export logger_file
import details/logger_group;   export logger_group

import oop/procfromtype; export procfromtype.implement

var defaultGroup_internal {.threadvar.}: LoggerGroup
template defaultGroup* : var LoggerGroup = defaultGroup_internal.lazyNew()

template log*(data: LogData, args: varargs[string, `$`]) = defaultGroup.log(data, args)

template define_sugar(kind): untyped =
  template kind*(logger: Logger; data: LogData, msg: varargs[string, `$`]) =
    var d {.gensym.} = data
    d.level = `lvl kind`
    logger.log(d, msg)
  template kind*(data: LogData, msg: varargs[string, `$`]) = defaultGroup.log(data, msg)
define_sugar debug
define_sugar info
define_sugar notice
define_sugar warn
define_sugar error
define_sugar fatal