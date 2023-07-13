import beyond/meta/modules
import beyond/meta/statements

var d_src = dir"tests/modules/src"
var d_root = dir"root"
var d_generated = dir"generated"
var root = mdl("root")
var internal = mdl"internal"

discard +/%..d_src:
  root
    .importExportModules_allowedExports
    .incl d_root
  +/%..allowExport d_root:
    +/%..dummy dir"manual_impremented":
      dummy mdl"prelude"
    +/%..d_generated:
      +/%..internal dir"internal":
        mdl"awstoken"
      dir"typedetails"
      internal
      mdl"typedefs"

discard internal.incl d_root/"generated/internal" # `/` => Directory
discard internal.incl d_generated//"typedefs" # `//` => Module

drop d_src
generate d_src
echo d_src.dumpTree