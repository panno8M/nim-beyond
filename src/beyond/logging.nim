## logging API with nim-standard implementation

import logging_api; export logging_api
import logging_formatshelf; export logging_formatshelf

type NimLogData* = object of LogData

template debug  *(args: varargs[string, `$`]) = defaultGroup.log(NimLogData(level: lvlDebug), args)
template info   *(args: varargs[string, `$`]) = defaultGroup.log(NimLogData(level: lvlInfo), args)
template notice *(args: varargs[string, `$`]) = defaultGroup.log(NimLogData(level: lvlNotice), args)
template warn   *(args: varargs[string, `$`]) = defaultGroup.log(NimLogData(level: lvlWarn), args)
template error  *(args: varargs[string, `$`]) = defaultGroup.log(NimLogData(level: lvlError), args)
template fatal  *(args: varargs[string, `$`]) = defaultGroup.log(NimLogData(level: lvlFatal), args)