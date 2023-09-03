import logging_core

import std/strutils
import std/os

type
  FileLogger* = ref object of Logger
    file*: File

  RollingFileLogger* = ref object of FileLogger
    maxLines: int
    curLine: int
    baseName: string
    baseMode: FileMode
    logFiles: int
    bufSize: int

method log*(logger: FileLogger; data: LogData; args: varargs[string, `$`]) =
  if data.level >= logger.levelThreshold:
    writeLine(logger.file, logger.format(data, @args))
    if data.level >= logger.flushThreshold: flushFile(logger.file)

proc defaultFilename*(): string =
  var (path, name, _) = splitFile(getAppFilename())
  result = changeFileExt(path / name, "log")

proc newFileLogger*(file: File,
                    levelThreshold = lvlAll,
                    format: LogFormat,
                    flushThreshold = defaultFlushThreshold): FileLogger =
  new(result)
  result.file = file
  result.levelThreshold = levelThreshold
  result.flushThreshold = flushThreshold
  result.format = format

proc newFileLogger*(filename = defaultFilename(),
                    mode: FileMode = fmAppend,
                    levelThreshold = lvlAll,
                    format: LogFormat,
                    bufSize: int = -1,
                    flushThreshold = defaultFlushThreshold): FileLogger =
  let file = open(filename, mode, bufSize = bufSize)
  newFileLogger(file, levelThreshold, format, flushThreshold)

proc countLogLines(logger: RollingFileLogger): int =
  let fp = open(logger.baseName, fmRead)
  for line in fp.lines():
    result.inc()
  fp.close()

proc countFiles(filename: string): int =

  result = 0
  var (dir, name, ext) = splitFile(filename)
  if dir == "":
    dir = "."
  for kind, path in walkDir(dir):
    if kind == pcFile:
      let llfn = name & ext & ExtSep
      if path.extractFilename.startsWith(llfn):
        let numS = path.extractFilename[llfn.len .. ^1]
        try:
          let num = parseInt(numS)
          if num > result:
            result = num
        except ValueError: discard

proc newRollingFileLogger*(filename = defaultFilename(),
                          mode: FileMode = fmReadWrite,
                          levelThreshold = lvlAll,
                          format: LogFormat,
                          maxLines: Positive = 1000,
                          bufSize: int = -1,
                          flushThreshold = defaultFlushThreshold): RollingFileLogger =
  new(result)
  result.levelThreshold = levelThreshold
  result.format = format
  result.maxLines = maxLines
  result.bufSize = bufSize
  result.file = open(filename, mode, bufSize = result.bufSize)
  result.curLine = 0
  result.baseName = filename
  result.baseMode = mode
  result.flushThreshold = flushThreshold

  result.logFiles = countFiles(filename)

  if mode == fmAppend:

    result.curLine = countLogLines(result)

proc rotate(logger: RollingFileLogger) =
  let (dir, name, ext) = splitFile(logger.baseName)
  for i in countdown(logger.logFiles, 0):
    let srcSuff = if i != 0: ExtSep & $i else: ""
    moveFile(dir / (name & ext & srcSuff),
            dir / (name & ext & ExtSep & $(i+1)))

method log*(logger: RollingFileLogger; data: LogData; args: varargs[string, `$`]) =
  if data.level >= logger.levelThreshold:
    if logger.curLine >= logger.maxLines:
      logger.file.close()
      rotate(logger)
      logger.logFiles.inc
      logger.curLine = 0
      logger.file = open(logger.baseName, logger.baseMode,
          bufSize = logger.bufSize)

    writeLine(logger.file, logger.format(data, @args))
    if data.level >= logger.flushThreshold: flushFile(logger.file)
    logger.curLine.inc