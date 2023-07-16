import std/tables
import std/sets
import std/macros
import std/strutils
import std/os

import meta/statements
import meta/statements/markdownkit

type
  AnnoKind = enum
    akTodo = "TODO"
    akFixme = "FIXME"
    akBug = "BUG"

  AnnoID = int
  AnnoSubject = object
    summary: string
    id: AnnoID
  AnnoToken = object
    kind: AnnoKind
    lineInfo: LineInfo
    contents: string

  AnnoSubjects = Table[AnnoID, AnnoSubject]
  AnnoTokens = OrderedTable[AnnoID, OrderedSet[AnnoToken]]

  AnnoMap = OrderedTable[AnnoSubject, seq[AnnoToken]]

var subjects {.compiletime.} : AnnoSubjects
var tokens {.compiletime.} : AnnoTokens
var todomap*: AnnoMap

var todoid_latest {.compileTime.} : int

template issueID: AnnoID =
  inc todoid_latest
  AnnoID todoid_latest


proc subject*(summary: string): AnnoSubject {.compileTime.} =
  result = AnnoSubject(summary: summary, id: issueID())
  subjects[result.id] = result
  tokens[result.id] = initOrderedSet[AnnoToken]()

template define(anno): untyped =
  macro anno*(marker: static AnnoSubject; includeThem: static bool; body): untyped =
    tokens[marker.id].incl AnnoToken(lineInfo: newEmptyNode().lineInfoObj, kind: `ak anno`, contents: (repr body)[1..^1])
    hint $`ak anno` & marker.summary, newEmptyNode()
    if includeThem: return body
  macro anno*(marker: static AnnoSubject; body): untyped =
    tokens[marker.id].incl AnnoToken(lineInfo: newEmptyNode().lineInfoObj, kind: `ak anno`, contents: (repr body)[1..^1])
    hint $`ak anno` & marker.summary, newEmptyNode()
    body
  macro anno*(marker: static AnnoSubject) =
    tokens[marker.id].incl AnnoToken(lineInfo: newEmptyNode().lineInfoObj, kind: `ak anno`)
    hint $`ak anno`  & ": " & marker.summary, newEmptyNode()

define TODO
define FIXME
define BUG


macro collect*: untyped =
  var subjects_table: Table[int, NimNode]
  var tokens_table: Table[int, seq[NimNode]]
  for id, subject in subjects:
    let summary = newlit subject.summary
    subjects_table[int id] = quote do:
      AnnoSubject(
        summary: `summary`,
        id: `id`,
        )
  for id, tokenset in tokens:
    var tokenlist = newSeq[NimNode]()
    for token in tokenset:
      let
        filename = newlit token.lineInfo.filename
        line = newlit token.lineInfo.line
        column = newlit token.lineInfo.column
        kind = newlit token.kind
        contents = newlit token.contents
      tokenlist.add quote do:
        AnnoToken(
          lineInfo: LineInfo(
            filename: `filename`,
            line: `line`,
            column: `column`),
          kind: `kind`,
          contents: `contents`,
        )
    tokens_table[int id] = tokenlist

  result = newStmtList()
  for id, subject in subjects_table:
    let tokens = nnkBracket.newTree(tokens_table[id])
    result.add quote do:
      todomap[`subject`] = @`tokens`


proc `$`(token: AnnoToken): string =
  # var lineinfo = token.lineinfo
  # lineinfo.filename = relativePath(lineinfo.filename, getCurrentDir())
  # $lineinfo
  $token.kind & ": " & relativePath(token.lineinfo.filename, getCurrentDir()) & ":" & $token.lineInfo.line & ":" & $token.lineInfo.column

proc report_markdown* : Statement =
  let list = ListSt.unordered_star()
  for subject, tokens in todomap:
    let tokenlist = ListSt.unordered_star()
    for token in tokens:
      discard +$$..tokenlist:
        +$$..ParagraphSt():
          $token
          +$$..OptionSt(eval: not token.contents.isEmptyOrWhitespace):
            # IndentSt(level:2)
            PrefixSt(style: "  | ").add(token.contents)

    discard +$$..list:
      +$$..CheckBoxSt(checked: false, head: subject.summary):
          tokenlist
  return list

