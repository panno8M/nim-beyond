import details/logging_core;    export logging_core

import details/logger_console; export logger_console
import details/logger_file;    export logger_file
import details/logger_group;   export logger_group

var defaultGroup_internal {.threadvar.}: LoggerGroup
template defaultGroup* : var LoggerGroup = defaultGroup_internal.lazyNew()

template log*(data: LogData, args: varargs[string, `$`]) = defaultGroup.log(data, args)

template debug  *[L: Logger](logger: L; data: LogData; args: varargs[string, `$`]) = logger.log(lvlDebug, data, args)
template info   *[L: Logger](logger: L; data: LogData; args: varargs[string, `$`]) = logger.log(lvlInfo, data, args)
template notice *[L: Logger](logger: L; data: LogData; args: varargs[string, `$`]) = logger.log(lvlNotice, data, args)
template warn   *[L: Logger](logger: L; data: LogData; args: varargs[string, `$`]) = logger.log(lvlWarn, data, args)
template error  *[L: Logger](logger: L; data: LogData; args: varargs[string, `$`]) = logger.log(lvlError, data, args)
template fatal  *[L: Logger](logger: L; data: LogData; args: varargs[string, `$`]) = logger.log(lvlFatal, data, args)

template debug  *(data: LogData; args: varargs[string, `$`]) = defaultGroup.log(lvlDebug, data, args)
template info   *(data: LogData; args: varargs[string, `$`]) = defaultGroup.log(lvlInfo, data, args)
template notice *(data: LogData; args: varargs[string, `$`]) = defaultGroup.log(lvlNotice, data, args)
template warn   *(data: LogData; args: varargs[string, `$`]) = defaultGroup.log(lvlWarn, data, args)
template error  *(data: LogData; args: varargs[string, `$`]) = defaultGroup.log(lvlError, data, args)
template fatal  *(data: LogData; args: varargs[string, `$`]) = defaultGroup.log(lvlFatal, data, args)