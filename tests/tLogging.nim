import beyond/logging

var L = newConsoleLogger()
var fL = newFileLogger("test.log", fmtStr = verboseFmtStr)
var rL = newRollingFileLogger("rolling.log", fmtStr = verboseFmtStr)
defaultGroup.loggers.add fL
defaultGroup.loggers.add rL
defaultGroup.loggers.add L
for i in 0 .. 25:
  info("hello", i)

var nilString: string
info "hello ", nilString