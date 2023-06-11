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

type NimIdentDef* = tuple
  name, `type`: string
  default: Option[string]
func idef*(name, `type`: string; default: Option[string]): NimIdentDef =
  (name: name, `type`: `type`, default: default)
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
  PrivateProc
  PublicProc
  PrivateFunc
  PublicFunc
  PrivateLambdaDef
  PublicLambdaDef
type NimProcSt* = ref object of ParagraphSt
  name*: string
  kind*: NimProcKind
  args*: seq[NimIdentDef]
  return_type*: Option[string]
  pragmas*: seq[string]

method render*(self: NimProcSt; cfg: RenderingConfig): seq[string] =
  result.add case self.kind
  of NimProcKind.PrivateProc:
    "proc " & self.name
  of NimProcKind.PublicProc:
    "proc " & self.name & "*"
  of NimProcKind.PrivateFunc:
    "func" & self.name
  of NimProcKind.PublicFunc:
    "func" & self.name & "*"
  of NimProcKind.PrivateLambdaDef:
    self.name & ": proc"
  of NimProcKind.PublicLambdaDef:
    self.name & "*: proc"

  if self.args.len != 0:
    result[0] &= "(" & $self.args & ")"
  if self.return_type.isSome:
    result[0] &= ": " & self.return_type.get
  if self.pragmas.len != 0:
    result[0] &= " {." & self.pragmas.join(", ") & ".}"

  let idt: Statement = IndentSt(level: 2).add self.children
  @[idt].forRenderedChild(cfg):
    result.add rendered

  if result.len > 1:
    result[0] &= " ="