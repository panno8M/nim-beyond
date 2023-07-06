import strformat, os
const cYELLOW = "\x1b[33m"
const cMAGENTA = "\x1b[35m"
const cDEFAULT = "\x1b[0m"
proc YELLOW(s: string): string = cYELLOW & s & cDEFAULT
proc MAGENTA(s: string): string = cMAGENTA & s & cDEFAULT
proc drop*(modules: seq[string]) =
  cd thisDir()
  for module in modules:
    if dirExists module:
      let subnims = module&"modulegenInfo.nims"
      if fileExists subnims:
        exec "nim --hints:off "&subnims
        if module.listDirs.len + module.listFiles.len == 1:
          echo &"""{MAGENTA "removing"} {YELLOW thisDir()/module} since there are no files..."""
          rmDir module
      else:
        echo &"""{MAGENTA "removing"} {YELLOW thisDir()/module} forcibly since there are no `genmdl.nims`..."""
        rmDir module

    elif fileExists module:
      echo &"""{MAGENTA "removing"} {YELLOW thisDir()/module}..."""
      rmFile module

when isMainModule:
  drop(modules)