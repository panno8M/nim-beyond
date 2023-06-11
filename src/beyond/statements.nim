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
  AtomSt* = ref object of Statement
  TextSt* = ref object of AtomSt
    text*: string

  # -- containers --
  ParagraphSt* = ref object of Statement

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

func text*(text: string): TextSt = TextSt(text: text)
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
  self.children.forRenderedChild(cfg):
    result.add rendered
  result = @[result.join(self.delimiter)]

method render*(self: ParagraphSt; cfg: RenderingConfig): seq[string] =
  self.children.forRenderedChild(cfg):
    result.add rendered

method render*(self: OptionSt; cfg: RenderingConfig): seq[string] =
  if self.eval:
    self.children.forRenderedChild(cfg):
      result.add rendered

template statement*[T: Statement](x: T): Statement = x
func statement*[T: Statement](x: seq[T]): Statement = ParagraphSt().add x
func statement*(x: string): Statement = text(x)

func add*[T: Statement](self: T; children: varargs[Statement, statement]): T =
  self.children.add @children
  self
func add*[T: Statement](self: T; children: seq[Statement]): T =
  self.children.add children
  self

macro body*[T: Statement](self: T; body): T =
  let children = stmtList_to_seq(body)
  let ret = gensym(nsklet, "self")
  result = quote do:
    let `ret` = `self`
    `ret`.children = `children`
    `ret`
macro addBody*[T: Statement](self: T; body): T =
  let children = stmtList_to_seq(body)
  quote do:
    `self`.add `children`

template `$`*(stmt: Statement): string = stmt.render(RenderingConfig()).join("\n")
