import ../macros
import ../modules

template pkg*(name: static string): Module = Module.package(name)
template mdl*(name: static string): Module = Module.module(name)

macro pkg*(name: static string; body): Module =
  var x = nnkBracket.newTree body[0..^1]
  result = quote do:
    pkg(`name`).takeSubmodules(`x`)
