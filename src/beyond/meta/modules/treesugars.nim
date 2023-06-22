runnableExamples:
  var root = pkg"path/to/prjroot":
    dontTouch do: pkg"manual_impremented":
        # The Package (manual_impremented/ and
        # manual_impremented.nim (import/export all modules in the directory) )
        # is not created.
      dontTouch mdl"prelude"
        # The module named "prelude.nim" is not created.
    pkg"generated":
      dontExport pkg"internal"
        # The Package (internal/ and internal.nim) is created
        # but not exported in generated.nim
      mdl"typedefs"
      pkg"typedetails"
        # Add generated modules to here lazily...

import ../../[
  macros,
]
import ../[
  modules,
]

template pkg*(name: static string): Module = Module.package(name)
template mdl*(name: static string): Module = Module.module(name)

macro pkg*(name: static string; body): Module =
  var x = nnkBracket.newTree body[0..^1]
  result = quote do:
    pkg(`name`).takeSubmodules(`x`)
