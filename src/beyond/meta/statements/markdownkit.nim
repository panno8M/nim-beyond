import ../statements {.all.}

type
  CheckBoxSt* = ref object of BlockSt
    checked*: bool

method render(self: CheckBoxSt; cfg: RenderingConfig): seq[string] =
  let checkbox =
    if self.checked: "[x] "
    else: "[ ] "
  let padding = "    "
  @[self.head].forRenderedChild(cfg):
    if i_rendered == 0:
      result.add checkbox & rendered
    else:
      result.add padding & rendered
  self.children.forRenderedChild(cfg):
    result.add rendered

type QuoteSt* = ref object of ParagraphSt

method render(self: QuoteSt; cfg: RenderingConfig): seq[string] =
  self.children.forRenderedChild(cfg):
    result.add newStringOfCap(rendered.len + 2)
    result[^1].add "> "
    result[^1].add rendered