import std/[
  strutils,
  sequtils,
  macros,
  sets,
]

type
  Statement* = ref object of RootObj
    children*: seq[Statement]

  # == atoms ==
  StmtAtom* = ref object of Statement
  StmtText* = ref object of StmtAtom
    text*: string

  # -- containers --
  StmtJoin* = ref object of Statement
    delimiter*: string
  StmtParagraph* = ref object of Statement

  # -- decorations --
  StmtDeco* = ref object of StmtParagraph

  StmtUnderline* = ref object of StmtDeco
    style*: string

  StmtPrefix* = ref object of StmtDeco
    prefix*: string
  StmtComment* = ref object of StmtDeco
    style*: string
    execute*: bool

  StmtIndent* = ref object of StmtDeco
    indent*: Natural = 2

  # -- controls --
  StmtOption* = ref object of StmtParagraph
    eval*: bool


  RenderingConfig* = object
    ignoreComment*: HashSet[string]

proc stmtList_to_seq(stmtList: NimNode): NimNode =
  nnkBracket.newTree(
    stmtList[0..^1].mapIt("statement".newCall it)
  ).prefix("@")

template forValidChild(children: seq[Statement]; body): untyped =
  for child {.inject.} in children.items:
    if child.isNil: continue
    body
template forRenderedChild(children: seq[Statement]; cfg; body): untyped =
  children.forValidChild:
    for rendered {.inject.} in child.render(cfg):
      body


method render*(self: Statement; cfg: RenderingConfig): seq[string] {.base.} =
  discard

func text*(text: string): StmtText = StmtText(text: text)
method render*(self: StmtText; cfg: RenderingConfig): seq[string] =
  self.text.splitLines

func underline*(style: string; children: seq[Statement]): StmtUnderline = StmtUnderline(style: style, children: children)
func underline*(style: string; children: varargs[Statement, statement]): StmtUnderline = underline(style, @children)
macro `underline/`*(style: string; children): StmtUnderline =
  let children = stmtList_to_seq(children)
  quote do: underline(`style`, `children`)

method render*(self: StmtUnderline; cfg: RenderingConfig): seq[string] =
  let styleLen = self.style.len
  self.children.forRenderedChild(cfg):
    result.add rendered
    var underline = newString(rendered.len)
    for i, ch in underline.mpairs:
      ch = self.style[i mod styleLen]
    result.add underline


func comment*(style: string; execute: bool; children: seq[Statement]): StmtComment = StmtComment(style: style, children: children, execute: execute)

method render*(self: StmtPrefix; cfg: RenderingConfig): seq[string] =
  self.children.forRenderedChild(cfg):
    result.add self.prefix & rendered
method render*(self: StmtComment; cfg: RenderingConfig): seq[string] =
  if self.style in cfg.ignoreComment:
    return
  if self.execute:
    self.children.forRenderedChild(cfg): result.add self.style & rendered
  else:
    self.children.forRenderedChild(cfg): result.add rendered


func indent*(indent: Natural = 2; children: seq[Statement]): StmtIndent = StmtIndent(indent: indent, children: children)
func indent*(indent: Natural = 2; children: varargs[Statement, statement]): StmtIndent = indent(indent, @children)
macro `indent/`*(indent: Natural; children): StmtIndent =
  let children = stmtList_to_seq(children)
  quote do: indent(`indent`, `children`)
method render*(self: StmtIndent; cfg: RenderingConfig): seq[string] =
  self.children.forRenderedChild(cfg):
    result.add " ".repeat(self.indent) & rendered


func join*(delimiter: string; children: seq[Statement]): StmtJoin = StmtJoin(delimiter: delimiter, children: children)
func join*(delimiter: string; children: varargs[Statement, statement]): StmtJoin = join(delimiter, @children)
macro `join/`*(delimiter: string; children): StmtJoin =
  let children = stmtList_to_seq(children)
  quote do: join(`delimiter`, `children`)

func oneline*(children: seq[Statement]): StmtJoin = join("", children)
func oneline*(children: varargs[Statement, statement]): StmtJoin = oneline(@children)
macro `oneline/`*(children): StmtJoin =
  let children = stmtList_to_seq(children)
  quote do: oneline(`children`)

method render*(self: StmtJoin; cfg: RenderingConfig): seq[string] =
  self.children.forRenderedChild(cfg):
    result.add rendered
  result = @[result.join(self.delimiter)]


func paragraph*(children: seq[Statement]): StmtParagraph = StmtParagraph(children: children)
func paragraph*[T: Statement](children: seq[T]): StmtParagraph = paragraph(children.mapIt statement it)
func paragraph*(children: varargs[Statement, statement]): StmtParagraph = paragraph(@children)
macro `paragraph/`*(children): StmtParagraph =
  let children = stmtList_to_seq(children)
  quote do: paragraph(`children`)

method render*(self: StmtParagraph; cfg: RenderingConfig): seq[string] =
  self.children.forRenderedChild(cfg):
    result.add rendered


func option*(eval: bool; children: seq[Statement]): StmtOption = StmtOption(eval: eval, children: children)
func option*(eval: bool; children: varargs[Statement, statement]): StmtOption = option(eval, @children)
macro `option/`*(eval: bool; children): StmtOption =
  let children = stmtList_to_seq(children)
  quote do: option(`eval`, `children`)
method render*(self: StmtOption; cfg: RenderingConfig): seq[string] =
  if self.eval:
    self.children.forRenderedChild(cfg):
      result.add rendered

template statement*(x: Statement): Statement = x
func statement*(x: string): Statement = text(x)

func add*(self: Statement; children: seq[Statement]) =
  self.children.add children
func add*[T: Statement](self: Statement; children: seq[T]) =
  for child in children: self.children.add statement child
func add*(self: Statement; children: varargs[Statement, statement]) =
  self.add @children

macro assignBlock*(self: var seq[Statement]; children) =
  let children = stmtList_to_seq(children)
  quote do: self = `children`
macro addBlock*(self: var seq[Statement]; children) =
  let children = stmtList_to_seq(children)
  quote do: self.add `children`

template `$`*(stmt: Statement): string = stmt.render(RenderingConfig()).join("\n")
