import std/[
  sequtils,
  strutils,
  macros,
  sets,
  options,
]
import ../statements {.all.}

const
  NimComment_str* = "# "
  NimDocComment_str* = "## "
  NimComment* = toHashSet [NimComment_str]
  NimDocComment* = toHashSet [NimDocComment_str]

func nimComment*(execute: bool; children: seq[Statement]): StmtComment = comment(NimComment_str, execute, children)
func nimComment*(execute: bool; children: varargs[Statement, statement]): StmtComment = nimComment(execute, @children)

func nimDocComment*(execute: bool; children: seq[Statement]): StmtComment = comment(NimDocComment_str, execute, children)
func nimDocComment*(execute: bool; children: varargs[Statement, statement]): StmtComment = nimDocComment(execute, @children)

macro `nimComment/`*(execute: bool; children): StmtComment =
  let children = stmtList_to_seq(children)
  quote do: nimComment(`execute`, `children`)
macro `nimDocComment/`*(execute: bool; children): StmtComment =
  let children = stmtList_to_seq(children)
  quote do: nimDocComment(`execute`, `children`)

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
type StmtNimProc* = ref object of StmtParagraph
  name*: string
  kind*: NimProcKind
  args*: seq[NimIdentDef]
  return_type*: Option[string]
  pragmas*: seq[string]

macro `nimProc/`*(kind: NimProcKind; name: string; args: seq[NimIdentDef]; return_type: Option[string]; pragmas: seq[string]; children): StmtNimProc =
  let children = stmtList_to_seq(children)
  quote do:
    StmtNimProc(
      name: `name`,
      kind: `kind`,
      args: `args`,
      return_type: `return_type`,
      pragmas: `pragmas`,
      children: `children`,
    )
method render*(self: StmtNimProc; cfg: RenderingConfig): seq[string] =
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

  result[0] &= "(" & $self.args & ")"
  if self.return_type.isSome:
    result[0] &= ": " & self.return_type.get
  if self.pragmas.len != 0:
    result[0] &= "{." & self.pragmas.join(", ") & ".}"

  let idt: Statement = indent(2, self.children)
  @[idt].forRenderedChild(cfg):
    result.add rendered

  if result.len > 1:
    result[0] &= " ="