import beyond/meta/modules
import beyond/meta/statements

var d_src = dir"tests/modules/src"
var d_root = dir"root"
var d_generated = dir"generated"
var root = mdl("root").setExport(esFriend)
var internal = mdl"internal"

discard +/%..d_src:
  root.inclDirs d_root
  +/%..d_root:
    +/%..dummy dir"manual_impremented":
      dummy mdl"prelude"
    +/%..d_generated:
      +/%..private dir"internal":
        mdl"awstoken"
      +/%..recommendPrivate dir"recommendInternal":
        mdl"userdata"
      dir"typedetails"
      internal
      mdl"typedefs"

discard internal.inclDirs d_root/"generated/internal" # `/` => Directory
discard internal.inclModules d_generated//"typedefs" # `//` => Module

generate d_src
echo d_src.dumpTree
# drop d_src