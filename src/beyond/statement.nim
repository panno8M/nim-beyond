import std/[
  strformat,
  strutils,
]

const
  siSentence = 0
  siHeader = 2
type
  StmtKind* {.pure.} = enum
    skSentence
    skDummy
  Statement* = ref object
    kind* = skSentence
    content*: string
    commentedout*: bool
    children*: seq[Statement]
    childIndent* = siHeader

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

func commentout*(stmt: Statement; `y/n` = true): Statement {.discardable.} =
  stmt.commentedout = `y/n`
  return stmt
func indentChildren*(stmt: Statement; childIndent: int; `y/n` = true): Statement {.discardable.} =
  if `y/n`:
    stmt.childIndent = childIndent
  return stmt

func commentout(str: string; `y/n` = true): string =
  if `y/n`: &"# {str}"
  else: str

func stringify*(stmt: Statement, indent: Natural): string =
  result.add stmt.content.commentout(stmt.commentedout).indent(indent) & '\n'
  for child in stmt.children:
    result.add child.stringify(indent+stmt.childIndent)

template `$`*(stmt: Statement): string = stmt.stringify(0)
