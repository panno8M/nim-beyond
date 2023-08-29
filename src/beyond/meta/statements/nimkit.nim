import std/[
  sequtils,
  strutils,
  sets,
  options,
]
import ../statements {.all.}

const
  NimComment_str* = "# "
  NimDocComment_str* = "## "
  NimComment* = toHashSet [NimComment_str]
  NimDocComment* = toHashSet [NimDocComment_str]

func nim*(_: typedesc[CommentSt]; execute: bool): CommentSt = CommentSt(
  style: NimComment_str,
  execute: execute)
func nimDoc*(_: typedesc[CommentSt]; execute: bool): CommentSt = CommentSt(
  style: NimDocComment_str,
  execute: execute)

type NimIdentDef* = object
  name*, `type`*: string
  default*: Option[string]
func idef*(name, `type`: string; default: Option[string]): NimIdentDef =
  NimIdentDef(name: name, `type`: `type`, default: default)
func idef*(name, `type`: string; default: string): NimIdentDef =
  idef(name, `type`, some default)
func idef*(name, `type`: string): NimIdentDef =
  idef(name, `type`, none string)

func `$`*(idef: NimIdentDef): string =
  result = idef.name & ": " & idef.`type`
  if idef.default.isSome:
    result &= " = " & (get idef.default)
func `$`*(idefs: seq[NimIdentDef]): string = idefs.mapIt($it).join("; ")
type NimProcKind* = enum
  npkProc = "proc"
  npkFunc = "func"
  npkMethod = "method"
  npkConverer = "converter"
  npkTemplate = "template"
  npkMacro = "macro"
type NimProcFlag* = enum
  npfExport
  npfOneline
type NimProcSt* = ref object of ParagraphSt
  kind*: NimProcKind
  flags*: set[NimProcFlag]
  name*: Option[string]
  args*: seq[NimIdentDef]
  return_type*: Option[string]
  pragmas*: seq[string]

method render*(self: NimProcSt; cfg: RenderingConfig): seq[string] =
  result.add $self.kind
  if self.name.isSome:
    result[0].add " "
    result[0].add (get self.name)
  if npfExport in self.flags:
    result[0].add "*"

  if self.args.len != 0:
    result[0] &= "(" & $self.args & ")"
  if self.return_type.isSome:
    result[0] &= ": " & self.return_type.get
  if self.pragmas.len != 0:
    result[0] &= " {." & self.pragmas.join(", ") & ".}"

  if npfOneline in self.flags:
    var oneline: seq[string]
    self.children.forRenderedChild(cfg):
      oneline.add rendered
    if oneline.len != 0:
      result[^1].add " = "
      result[^1].add oneline.join("; ")
  else:
    self.children.forRenderedChild(cfg):
      result.add "  " & rendered
    if result.len > 1:
      result[0] &= " ="