import std/[times, os]
import details/logging_core

template date*: string =
  bind getDateStr
  getDateStr()
template time*: string =
  bind getClockStr
  getClockStr()
template datetime*: string =
  bind getDateStr
  bind getClockStr
  getDateStr() & "T" & getClockStr()
template app*: string =
  bind getAppFilename
  getAppFilename()
template appdir*: string =
  bind getAppFilename
  bind splitFile
  getAppFilename().splitFile.dir
template appname*: string =
  bind getAppFilename
  bind splitFile
  getAppFilename().splitFile.name
template levelid*: string =
  mixin data
  $($data.level)[0]
template levelname*: string =
  mixin data
  $data.level