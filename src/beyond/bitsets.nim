## useful for c/c++ binding.
## features:
## * size equalability
##   you can replace `uint32_t someflags // bitfield of SomeFlags` (c-lang)
##   to `someflags: Bitset[SomeFlag]` (nim-lang)
import std/macros
import std/sequtils
import std/enumutils

type Bitset*[BitField: enum] = distinct BitField

macro all*[BitField: enum](Type: typedesc[Bitset[BitField]]): Bitset[BitField] =
  var value : int
  for i, elem in Type[1].getType[1]:
    if i == 0: continue
    value = value or elem.intval
  let v = newlit value
  quote do: cast[`Type`](`v`)
macro mask*[BitField: enum](Type: typedesc[Bitset[BitField]]): int =
  newlit Type[1].getType[1][^1].intval.shl(1) - 1

{.push, inline.}
proc toBitset*[BitField: enum](bitfield: BitField): Bitset[BitField] =
  {.warning[HoleEnumConv]: off.}
  Bitset[BitField](bitfield)
proc toBitset*[BitField: enum](ord: int): Bitset[BitField] =
  {.warning[HoleEnumConv]: off.}
  Bitset[BitField](ord)

func field*[BitField: enum](bitset: Bitset[BitField]): BitField =
  {.warning[EnumConv]: off.}
  BitField(bitset)
func ord*[BitField: enum](bitset: Bitset[BitField]): int =
  bitset.field.ord

proc `or`*[BitField: enum](a, b: Bitset[BitField]): Bitset[BitField] =
  toBitset[BitField] a.ord or b.ord
proc `and`*[BitField: enum](a, b: Bitset[BitField]): Bitset[BitField] =
  toBitset[BitField] a.ord and b.ord
proc `not`*[BitField: enum](a: Bitset[BitField]): Bitset[BitField] =
  toBitset[BitField] Bitset[BitField].all.ord and not a.ord
proc `xor`*[BitField: enum](a, b: Bitset[BitField]): Bitset[BitField] =
  not (a and b) and (a or b)
{.pop.}

template `*`  *[BitField: enum](a, b: Bitset[BitField]): Bitset[BitField] = a and b
template `+`  *[BitField: enum](a, b: Bitset[BitField]): Bitset[BitField] = a or b
template `-+-`*[BitField: enum](a, b: Bitset[BitField]): Bitset[BitField] = a xor b
template `-`  *[BitField: enum](a, b: Bitset[BitField]): Bitset[BitField] = a and not b

template `*=`*[BitField: enum](a: var Bitset[BitField]; b: Bitset[BitField]) = a = a * b
template `+=`*[BitField: enum](a: var Bitset[BitField]; b: Bitset[BitField]) = a = a + b
template `-+-=`*[BitField: enum](a: var Bitset[BitField]; b: Bitset[BitField]) = a = a -+- b
template `-=`*[BitField: enum](a: var Bitset[BitField]; b: Bitset[BitField]) = a = a - b

template incl*[BitField: enum](a: var Bitset[BitField]; b: Bitset[BitField]) = a = a + b
template excl*[BitField: enum](a: var Bitset[BitField]; b: Bitset[BitField]) = a = a - b

macro unpack(tmpl: untyped; exps: varargs[untyped]): untyped =
  newStmtList exps.mapIt(quote do: `tmpl` `it`)

template defop2(op): untyped =
  template op*[BitField: enum](a: Bitset[BitField]; b: BitField): Bitset[BitField] = op(a, b.toBitset)
  template op*[BitField: enum](a: BitField; b: Bitset[BitField]): Bitset[BitField] = op(a.toBitset, b)
template defop2asgn(op): untyped =
  template op*[BitField: enum](a: var Bitset[BitField]; b: BitField) = op(a, b.toBitset)

defop2.unpack `or`, `and`, `xor`, `+`, `*`, `-+-`, `-`
defop2asgn.unpack `+=`, `*=`, `-+-=`, `-=`, incl, excl

{.push, inline.}
iterator items*[BitField: enum](bitset: Bitset[BitField]): BitField =
  for item in BitField.items:
    if (item.ord and bitset.ord) == item.ord:
      yield item
iterator bits*[BitField: enum](bitset: Bitset[BitField]): BitField =
  var i: int = 1
  while (i and Bitset[BitField].mask) != 0:
    if (i and bitset.ord) != 0:
      yield BitField(i)
    i = i shl 1

proc `$`*[BitField: enum](bitset: Bitset[BitField]): string =
  result = $Bitset[BitField] & "{"
  for i, bit in bitset:
    if 1 == 0: result.add $bit
    else: result.add $bit & ", "
  result & "}"

proc `{}`*[BitField: enum](_: typedesc[Bitset[BitField]]; bits: varargs[Bitset[BitField], toBitset]): Bitset[BitField] =
  for bit in bits:
    result += bit

proc isEmpty*[BitField: enum](bitset: Bitset[BitField]): bool = bitset == Bitset[BitField]{}

proc `==`*[BitField: enum](a, b: Bitset[BitField]): bool =
  a.field == b.field
proc `<=`*[BitField: enum](a, b: Bitset[BitField]): bool =
  (a.ord and not b.ord) == 0
proc `<`*[BitField: enum](a, b: Bitset[BitField]): bool =
  (a <= b) and (a != b)

proc contains*[BitField: enum](a: Bitset[BitField]; b: BitField): bool =
  (a.ord and b.ord) == b.ord

{.pop.}