import beyond/logging

var L = newConsoleLogger(format= format_DEFAULT)
var fL = newFileLogger("test.log", format= format_VERBOSE)
var rL = newRollingFileLogger("rolling.log", format = format_VERBOSE)

defaultGroup.loggers.add(@[fL, rL, L])
for i in 0 .. 5:
  info "hello", i

var nilString: string
info "hello", nilString