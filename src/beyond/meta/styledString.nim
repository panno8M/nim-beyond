import std/strutils
import std/sequtils

type StyledString* = object of RootObj
  native*: string
  ranges*: seq[HSlice[int, int]]

converter `$`*[T: StyledString](w: T): string = w.native

iterator items*(w: StyledString): string =
  for r in w.ranges:
    yield w.native[r]

type
  SomeStyledString* = concept type t
    t is StyledString
  ScannableStyledString* = concept type t
    t is StyledString
    t.scan(string) is t


template convert*[TA,TB: SomeStyledString](A: typedesc[TA]; words: TB): TA = words.convert(A)
template `>=>`*[TA,TB: SomeStyledString](words: TA; B: typedesc[TB]): TB = words.convert(B)

template scan*(s: string; T: typedesc[ScannableStyledString]): T = T.scan(s)
template `>!>`*(s: string; T: typedesc[ScannableStyledString]): T = T.scan(s)

proc imitate*(T: typedesc[SomeStyledString]; str: string): T = T(native: str, ranges: @[str.low..str.high])

proc addIfValid(ss: var seq[HSlice[int,int]]; s: HSlice[int,int]) =
  if s.a <= s.b:
    ss.add s

const keywords* = [
  "addr", "and", "as", "asm", "bind", "block", "break", "case", "cast", "concept",
  "const", "continue", "converter", "defer", "discard", "distinct", "div", "do",
  "elif", "else", "end", "enum", "except", "export", "finally", "for", "from",
  "func", "if", "import", "in", "include", "interface", "is", "isnot", "iterator",
  "let", "macro", "method", "mixin", "mod", "nil", "not", "notin", "object", "of",
  "or", "out", "proc", "ptr", "raise", "ref", "return", "shl", "shr", "static",
  "template", "try", "tuple", "type", "using", "var", "when", "while", "xor", "yield",
]

# ====================================================================================== #

type NimVar* = object of StyledString
type NimType* = object of StyledString

proc quoted*(w: NimVar): NimVar = NimVar(native: "`" & w.native & "`", ranges: w.ranges.mapIt(it.a.succ..it.b.succ))

# ====================================================================================== #

type Camel* = object of StyledString
type Camel_Continuos* = object of Camel

type Snake* = object of StyledString

# ====================================================================================== #

proc scan*(_: typedesc[Camel]; s: string): Camel =
  result.native = s
  var w: HSlice[int, int]
  for i in 0..<s.len:
    if s[i].isUpperAscii:
      w.b = i - 1
      result.ranges.addIfValid w
      w.a = i
  w.b = s.high
  result.ranges.addIfValid w

proc scan*(_: typedesc[Camel_Continuos]; s: string): Camel_Continuos =
  result.native = s
  var w: HSlice[int, int]
  var isUpper: (bool, bool)
  for i in 0..s.high:
    isUpper[1] = s[i].isUpperAscii
    if not isUpper[0] and isUpper[1]:
      w.b = i - 1
      result.ranges.addIfValid w
      w.a = i
    swap(isUpper[0], isUpper[1])
  w.b = s.high
  result.ranges.addIfValid w

proc scan*(_: typedesc[Snake]; s: string): Snake =
  result.native = s
  var w: HSlice[int, int]
  for i in 0..s.high:
    if s[i] == '_':
      w.b = i-1
      result.ranges.addIfValid w
      w.a = i+1
  w.b = s.high
  result.ranges.addIfValid w

# ====================================================================================== #

proc convert*(w: Camel; _: typedesc[NimType]): NimType =
  result.native = newStringOfCap(w.native.len)
  result.ranges = w.ranges
  for i, r in w.ranges:
    if i == 0:
      result.native.add w.native[r.a].toUpperAscii
      if r.b - r.a > 0:
        result.native.add w.native[r.a+1..r.b]
    else:
      result.native.add w.native[r]
converter nimType*(w: Camel): NimType = w.convert NimType

proc convert*(w: Camel_Continuos; _: typedesc[NimType]): NimType =
  result.native = newStringOfCap(w.native.len)
  result.ranges = w.ranges
  for i, r in w.ranges:
    if i == 0:
      result.native.add w.native[r.a].toUpperAscii
    else:
      result.native.add w.native[r.a]
    if r.b - r.a > 0:
      result.native.add w.native[r.a+1..r.b].toLowerAscii
converter nimType*(w: Camel_Continuos): NimType = w.convert NimType

proc convert*(w: Snake; _: typedesc[NimType]): NimType =
  result.native = newStringOfCap(w.native.len)
  var rd: HSlice[int, int]
  for i, r in w.ranges:
    result.native.add w.native[r.a].toUpperAscii
    if r.b - r.a > 0:
      result.native.add w.native[r.a+1..r.b].toLowerAscii

    rd.b = result.native.high
    result.ranges.addIfValid rd
    rd.a = rd.b+1
  rd.b = result.native.high
  result.ranges.addIfValid rd
converter nimType*(w: Snake): NimType = w.convert NimType

proc convert*(w: Snake; _: typedesc[NimVar]): NimVar =
  result.native = newStringOfCap(w.native.len)
  var rd: HSlice[int, int]
  for i, r in w.ranges:
    if i == 0:
      result.native.add w.native[r].toLowerAscii
    else:
      result.native.add w.native[r.a].toUpperAscii
      if r.b - r.a > 0:
        result.native.add w.native[r.a+1..r.b].toLowerAscii

    rd.b = result.native.high
    result.ranges.addIfValid rd
    rd.a = rd.b+1
  rd.b = result.native.high
  result.ranges.addIfValid rd

  if result.ranges.len == 1 and result.native in keywords:
    result.native = "`" & result.native & "`"
    inc result.ranges[0].a
    inc result.ranges[0].b
converter nimVar*(w: Snake): NimVar = w.convert NimVar



# ====================================================================================== #

when isMainModule:
  var cache: string

  cache = ""
  for word in "aBCd0eFGhI" >!> Camel >=> NimType:
    cache &= word
    cache &= " "
  echo cache

  cache = ""
  for word in "aBCd0eFGhI" >!> Camel_Continuos >=> NimType:
    cache &= word
    cache &= " "
  echo cache

  cache = ""
  for word in "_AB_c_de_fGH_" >!> Snake >=> NimVar:
    cache &= word
    cache &= " "
  echo cache

  echo "Xor" >!> Snake >=> NimVar