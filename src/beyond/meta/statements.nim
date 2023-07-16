import std/[
  strutils,
  sets,
]
import ../macros

type
  Statement* = ref object of RootObj
    children*: seq[Statement]

proc ListStylize_ordered_decimal*(i: Positive): string = $i&". "
proc ListStylize_unordered_star*(i: Positive): string = "* "

type TreeStylizeToken = enum
  tstHead
  tstBody
  tstTail
  tstNone
proc TreeStylize_default*(token: TreeStylizeToken): string =
  case token
  of tstHead: "├─ "
  of tstBody: "│  "
  of tstTail: "└─ "
  of tstNone: "   "

type
  # == atoms ==
  AtomSt* = ref object of Statement
  TextSt* = ref object of AtomSt
    text*: string

  # -- containers --
  ParagraphSt* = ref object of Statement

  ListSt* = ref object of ParagraphSt
    stylize* = ListStylize_ordered_decimal

  BlockSt* = ref object of ParagraphSt
    head*: Statement
    indentLevel*:Natural = 2

  TreeSt* = ref object of BlockSt
    stylize* = TreeStylize_default

  # -- decorations --
  DecoSt* = ref object of ParagraphSt

  UnderlineSt* = ref object of DecoSt
    style*: string

  PrefixSt* = ref object of DecoSt
    style*: string
  CommentSt* = ref object of PrefixSt
    execute*: bool

  IndentSt* = ref object of DecoSt
    level*: Natural = 2

  # -- controls --
  OptionSt* = ref object of ParagraphSt
    eval*: bool

  JoinSt* = ref object of ParagraphSt
    delimiter*: string

  RenderingConfig* = object
    ignoreComment*: HashSet[string]

proc ordered_decimal*(_: typedesc[ListSt]): ListSt =
  ListSt(stylize: ListStylize_ordered_decimal)
proc unordered_star*(_: typedesc[ListSt]): ListSt =
  ListSt(stylize: ListStylize_unordered_star)

template forValidChild(children: seq[Statement]; body): untyped =
  for i_child {.inject.}, child {.inject.} in children.pairs:
    if child.isNil: continue
    body
template forRenderedChild(children: seq[Statement]; cfg; body): untyped =
  children.forValidChild:
    for i_rendered {.inject.}, rendered {.inject.} in child.render(cfg):
      body

converter text*(text: string): TextSt {.noSideEffect.} = TextSt(text: text)
func oneline*(_: typedesc[JoinSt]): JoinSt = JoinSt(delimiter: "")

method render*(self: Statement; cfg: RenderingConfig): seq[string] {.base.} =
  discard

method render*(self: TextSt; cfg: RenderingConfig): seq[string] =
  self.text.splitLines

method render*(self: UnderlineSt; cfg: RenderingConfig): seq[string] =
  let styleLen = self.style.len
  self.children.forRenderedChild(cfg):
    result.add rendered
    var underline = newString(rendered.len)
    for i, ch in underline.mpairs:
      ch = self.style[i mod styleLen]
    result.add underline

method render*(self: PrefixSt; cfg: RenderingConfig): seq[string] =
  self.children.forRenderedChild(cfg):
    result.add self.style & rendered

method render*(self: CommentSt; cfg: RenderingConfig): seq[string] =
  if self.style in cfg.ignoreComment:
    return
  if self.execute:
    self.children.forRenderedChild(cfg): result.add self.style & rendered
  else:
    self.children.forRenderedChild(cfg): result.add rendered

method render*(self: IndentSt; cfg: RenderingConfig): seq[string] =
  self.children.forRenderedChild(cfg):
    result.add " ".repeat(self.level) & rendered

method render*(self: JoinSt; cfg: RenderingConfig): seq[string] =
  result = newSeq[string](1)
  var needsdelim = false
  self.children.forRenderedChild(cfg):
    if needsdelim: result[0].add self.delimiter
    result[0].add rendered
    needsdelim = true

method render*(self: ParagraphSt; cfg: RenderingConfig): seq[string] =
  self.children.forRenderedChild(cfg):
    result.add rendered

method render*(self: OptionSt; cfg: RenderingConfig): seq[string] =
  if self.eval:
    self.children.forRenderedChild(cfg):
      result.add rendered

method render*(self: BlockSt; cfg: RenderingConfig): seq[string] =
  let indent = " ".repeat(self.indentLevel)
  result.add self.head.render(cfg)
  self.children.forRenderedChild(cfg):
    result.add indent & rendered

method render*(self: TreeSt; cfg: RenderingConfig): seq[string] =
  let
    body = self.stylize(tstBody)
    head = self.stylize(tstHead)
    tail = self.stylize(tstTail)
    none = self.stylize(tstNone)
  template token: string =
    if i_rendered != 0:
      if i_child != self.children.high: body
      else:                             none
    else:
      if i_child != self.children.high: head
      else:                             tail
  result.add self.head.render(cfg)
  self.children.forRenderedChild(cfg):
    result.add token & rendered

method render*(self: ListSt; cfg: RenderingConfig): seq[string] =
  self.children.forValidChild:
    let style = self.stylize(i_child+1)
    let space = " ".repeat(style.len)
    for i, rendered in child.render(cfg):
      if i == 0:
        result.add style & rendered
      else:
        result.add space & rendered

template `$$`*[T: Statement](x: T): Statement = x
func `$$`*[T: Statement](x: seq[T]): Statement =
  result = ParagraphSt()
  for xi in x:
    result.children.add $$xi
converter `$$`*(x: string): Statement {.noSideEffect.} = text(x)

func add*[T: Statement](self: T; children: varargs[Statement, `$$`]): T =
  self.children.add @children
  self
func add*[T: Statement](self: T; children: seq[Statement]): T =
  self.children.add children
  self

macro addBody*[T: Statement](self: T; body): T =
  let children = stmtList_to_seq(body, "$$")
  quote do:
    `self`.add `children`

template `+$$..`*[T: Statement](self: T; body): T =
  self.addBody body

template `$`*(stmt: Statement): string = stmt.render(RenderingConfig()).join("\n")
