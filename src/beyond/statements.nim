import std/[
  strutils,
  sequtils,
  options,
]

const
  siSentence = 0
  siHeader = 2
  siPadding = 0
type
  StmtKind* {.pure.} = enum
    skSentence
    skDummy
  StmtCommentStat* {.pure.} = enum
    scsPlain
    scsDocComment
    scsComment
  Statement* = ref object
    kind* = skSentence
    content*: string
    commentStat*: StmtCommentStat
    children*: seq[Statement]
    childIndent* = siHeader
    paddingIndent* = siPadding
  ConfigStringify* = object
    ignoreComment*: bool
    ignoreDocComment*: bool


func sentence*(_: typedesc[Statement]; content: string): Statement =
  Statement(
    kind: skSentence,
    content: content,
    childIndent: siSentence,
  )
func header*(_: typedesc[Statement]; content: string): Statement =
  Statement(
    kind: skSentence,
    content: content,
    childIndent: siHeader,
  )
func blank*(_: typedesc[Statement]): Statement =
  Statement(
    kind: skSentence,
    childIndent: siSentence,
  )
func dummy*(_: typedesc[Statement]): Statement =
  Statement(
    kind: skDummy,
    childIndent: siSentence,
  )

func add*(stmt: Statement; children: varargs[Statement]): Statement {.discardable.} =
  stmt.children.add children
  return stmt

func asComment*(stmt: Statement; `y/n` = true): Statement {.discardable.} =
  if `y/n`:
    stmt.commentStat = scsComment
  return stmt
func asDocComment*(stmt: Statement; `y/n` = true): Statement {.discardable.} =
  if `y/n`:
    stmt.commentStat = scsDocComment
  return stmt
func indentChildren*(stmt: Statement; lvIndent: int; `y/n` = true): Statement {.discardable.} =
  if `y/n`:
    stmt.childIndent = lvIndent
  return stmt
func indentSelf*(stmt: Statement; lvIndent: int; `y/n` = true): Statement {.discardable.} =
  if `y/n`:
    stmt.paddingIndent = lvIndent
  return stmt

func applyComment(str: string; stat: StmtCommentStat; cfg: ConfigStringify): Option[string] =
  case stat
  of scsPlain:
    some str
  of scsDocComment:
    if cfg.ignoreDocComment:
      none string
    else:
      some str.splitLines.mapIt("## "&it).join("\n")
  of scsComment:
    if cfg.ignoreComment:
      none string
    else:
      some str.splitLines.mapIt("# "&it).join("\n")

func stringify*(stmt: Statement; cfg: ConfigStringify; indent: Natural = 0): string =
  let idtSlf = indent+stmt.paddingIndent
  let idtCld = idtSlf+stmt.childIndent
  case stmt.kind
  of skSentence:
    let commented = stmt.content.applyComment(stmt.commentStat, cfg)
    if commented.isSome:
      result.add (get commented).indent(idtSlf) & '\n'
  of skDummy:
    discard
  for child in stmt.children:
    if child.isNil: continue
    result.add child.stringify(cfg, idtCld)

template `$`*(stmt: Statement): string = stmt.stringify(ConfigStringify())
