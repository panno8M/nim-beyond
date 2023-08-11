import std/tables
import std/sets
import std/macros
import std/strutils
import std/os

import meta/statements
import meta/statements/markdownkit

export sets.incl

type
  AnnoKind = enum
    akTodo = "TODO"
    akFixme = "FIXME"
    akBug = "BUG"

  AnnoID = distinct int
  AnnoSubject = object
    summary: string
    id: AnnoID
    parent: AnnoID
    comment: string
    eval: bool = true
  AnnoToken = object
    kind: AnnoKind
    lineInfo: LineInfo
    comment: string
    contents: string

  AnnoSubjects = Table[AnnoID, AnnoSubject]
  AnnoTokens = OrderedTable[AnnoID, OrderedSet[AnnoToken]]

var subjects {.compiletime.} : AnnoSubjects
var tokens {.compiletime.} : AnnoTokens

var collected_subjects : AnnoSubjects
var collected_tokens : AnnoTokens

proc `==`*(a,b: AnnoID): bool {.borrow.}
proc isNone*(x: AnnoID): bool = (int x) == 0

proc `$`(token: AnnoToken): string =
  let path = relativePath(token.lineinfo.filename, getCurrentDir())
  let comment =
    if token.comment.isEmptyOrWhitespace: ""
    else: token.comment & " "
  $token.kind & ": " & comment & "(" & path & ":" & $token.lineInfo.line & ":" & $token.lineInfo.column & ")"

var todoid_latest {.compileTime.} : int
template issueID: AnnoID =
  inc todoid_latest
  AnnoID todoid_latest


proc subject*(summary: string): AnnoSubject {.compileTime.} =
  result = AnnoSubject(summary: summary, id: issueID())
  subjects[result.id] = result
  tokens[result.id] = initOrderedSet[AnnoToken]()

proc setParent*(child, parent: AnnoSubject): AnnoSubject =
  result = AnnoSubject(summary: child.summary, id: child.id, parent: parent.id)
  subjects[result.id] = result

proc comment*(subj: AnnoSubject; comment: string): AnnoSubject {.compileTime.} =
  result = subj
  result.comment = comment
proc eval*(subj: AnnoSubject; eval: bool): AnnoSubject {.compileTime.} =
  result = subj
  result.eval = eval
proc eval*(subj: AnnoSubject): AnnoSubject {.compileTime.} =
  result = subj
  result.eval = true
proc ignore*(subj: AnnoSubject): AnnoSubject {.compileTime.} =
  result = subj
  result.eval = false

template hintmessage(token: AnnoToken, subj: AnnoSubject): string =
  let msg = $token.kind & ": " & subj.summary
  if token.comment.isEmptyOrWhitespace: msg
  else: msg & ".. " & token.comment
template define(anno): untyped =
  macro anno*(subj: static AnnoSubject; body : untyped = nil): untyped =
    let token = AnnoToken(lineInfo: newEmptyNode().lineInfoObj, kind: `ak anno`, comment: subj.comment, contents: (repr body)[1..^1])
    tokens[subj.id].incl token
    hint hintmessage(token, subj), newEmptyNode()
    if body.kind != nnkNilLit and subj.eval: return body

define TODO
define FIXME
define BUG


macro collect*: untyped =
  result = newStmtList()
  for id, subject in subjects:
    let summary = newlit subject.summary
    let parent = newlit int subject.parent
    result.add quote do:
      collected_subjects[`id`] = AnnoSubject(
        summary: `summary`,
        id: `id`,
        parent: AnnoID `parent`,
        )
  for id, tokenset in tokens:
    var tokenlist = newNimNode(nnkBracket)
    for token in tokenset:
      let
        filename = newlit token.lineInfo.filename
        line = newlit token.lineInfo.line
        column = newlit token.lineInfo.column
        kind = newlit token.kind
        comment = newlit token.comment
        contents = newlit token.contents
      tokenlist.add quote do:
        AnnoToken(
          lineInfo: LineInfo(
            filename: `filename`,
            line: `line`,
            column: `column`),
          kind: `kind`,
          comment: `comment`,
          contents: `contents`,
        )
    result.add quote do:
      collected_tokens[`id`] = toOrderedSet `tokenlist`


proc report_markdown* : Statement =
  var checkboxes: Table[AnnoSubject, CheckBoxSt]

  for id, subject in collected_subjects:
    let tokenlist = ListSt.unordered_star()
    for token in collected_tokens[id]:
        discard +$$..tokenlist:
          +$$..BlockSt(head: $token):
            +$$..OptionSt(eval: not token.contents.isEmptyOrWhitespace):
              QuoteSt().add(token.contents)

    checkboxes[subject] = CheckBoxSt(checked: false, head: subject.summary)
        .add( IndentSt(level: 2).add(tokenlist))
  for subject, checkbox in checkboxes:
    if not subject.parent.isNone:
      checkboxes[collected_subjects[subject.parent]].children[^1].children.insert(checkbox, 0)

  let list = ListSt.unordered_star()
  for subject, checkbox in checkboxes:
    if subject.parent.isNone:
      discard list.add checkbox
  return list
