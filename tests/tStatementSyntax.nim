import beyond/[
  statements,
  statements/nimtraits,
]
import std/strutils

var stmt = ParagraphSt().body:
  text "hello, statement!"
  ""
  IndentSt(level: 2).body:
    "<INDENT level= 2/>"
  OptionSt(eval: true).body:
    "<OPTION eval= true/>"
  OptionSt(eval: false).body:
    "<OPTION eval= false/>"
  CommentSt.nim(execute= true).body:
    "<NIM-COMMENT execute= true/>"
  CommentSt.nim(execute= false).body:
    "<NIM-COMMENT execute= false/>"
  CommentSt.nimDoc(execute= true).body:
    "<NIM-DOC-COMMENT execute= true/>"
  UnderlineSt(style: "-*-").body:
    "<UNDERLINE style= \"-*-\"/>"
  JoinSt.oneline().body:
    "<ONELINE>"
    "<TEXT text=1/>"
    "<TEXT text=2/>"
    "<TEXT text=3/>"
    "</ONELINE>"

discard stmt.addBody:
  "THIS"
  IndentSt(level: 2).body:
    "IS"
    CommentSt.nim(execute= true).body:
      "A"
      UnderlineSt(style: "~").body:
        "COMPLEX"
    JoinSt.oneline.body:
      "STA"
      "TEM"
      "ENT"

echo stmt