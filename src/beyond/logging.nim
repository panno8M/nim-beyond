import details/logging_core;    export logging_core
import details/logging_console; export logging_console
import details/logging_file;    export logging_file
import details/logging_group;   export logging_group

var defaultGroup_internal {.threadvar.}: LoggerGroup
template defaultGroup* : var LoggerGroup = defaultGroup_internal.lazyNew()

template debug*[T: Logger](logger: T; args: varargs[string, `$`]) = logger.log(lvlDebug, args)
template info*[T: Logger](logger: T; args: varargs[string, `$`]) = logger.log(lvlInfo, args)
template notice*[T: Logger](logger: T; args: varargs[string, `$`]) = logger.log(lvlNotice, args)
template warn*[T: Logger](logger: T; args: varargs[string, `$`]) = logger.log(lvlWarn, args)
template error*[T: Logger](logger: T; args: varargs[string, `$`]) = logger.log(lvlError, args)
template fatal*[T: Logger](logger: T; args: varargs[string, `$`]) = logger.log(lvlFatal, args)

template log*(level: Level, args: varargs[string, `$`]) = defaultGroup.log(level, args)
template debug *(args: varargs[string, `$`]) = defaultGroup.debug(args)
template info  *(args: varargs[string, `$`]) = defaultGroup.info(args)
template notice*(args: varargs[string, `$`]) = defaultGroup.notice(args)
template warn  *(args: varargs[string, `$`]) = defaultGroup.warn(args)
template error *(args: varargs[string, `$`]) = defaultGroup.error(args)
template fatal *(args: varargs[string, `$`]) = defaultGroup.fatal(args)
