import beyond/meta/[
  statements,
  statements/nimtraits,
]
import std/strutils

var stmt = +$$..ParagraphSt():
  text "hello, statement!"
  ""
  +$$..IndentSt(level: 2):
    "<INDENT level= 2/>"
  +$$..OptionSt(eval: true):
    "<OPTION eval= true/>"
  +$$..OptionSt(eval: false):
    "<OPTION eval= false/>"
  +$$..CommentSt.nim(execute= true):
    "<NIM-COMMENT execute= true/>"
  +$$..CommentSt.nim(execute= false):
    "<NIM-COMMENT execute= false/>"
  +$$..CommentSt.nimDoc(execute= true):
    "<NIM-DOC-COMMENT execute= true/>"
  +$$..UnderlineSt(style: "-*-"):
    "<UNDERLINE style= \"-*-\"/>"
  +$$..JoinSt.oneline():
    "<ONELINE>"
    "<TEXT text=1/>"
    "<TEXT text=2/>"
    "<TEXT text=3/>"
    "</ONELINE>"

discard +$$..stmt:
  "THIS"
  +$$..IndentSt(level: 2):
    "IS"
    +$$..CommentSt.nim(execute= true):
      "A"
      +$$..UnderlineSt(style: "~"):
        "COMPLEX"
    +$$..JoinSt.oneline:
      "STA"
      "TEM"
      "ENT"

discard stmt.add @[
  text"you can add",
  text"seq[T: Statement]",
  text"that will auto-convert into seq[Statement]"
]

discard +$$..stmt:
  +$$..TreeSt(head: text "And you can draw"):
    +$$..ListSt(stylize: ListStylize_unordered_star):
      "directory"
      "tree"
    +$$..TreeSt(head: "diagram"):
      +$$..TreeSt(head: "by"):
        "using"
        "TreeSt"
    "object."

echo stmt
