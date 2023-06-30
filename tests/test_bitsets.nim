import std/unittest
import beyond/bitsets
type TEST_BITS {.size: sizeof(cuint).} = enum
  A   = 0b00001
  B   = 0b00010
  C   = 0b00100
  ABC = 0b00111
  D   = 0b10000

let
  a: Bitset[TEST_BITS] = Bitset{A}
  b = Bitset{B}
  c = Bitset{C}
  ab = Bitset{A, B}
  abc = Bitset{A, B, C}
  abcd = Bitset{A, B, C, D}
  bcd = Bitset{B, C, D}
  emp = Bitset[TEST_BITS]{}

test "size":
  check sizeof(TEST_BITS) != sizeof(set[TEST_BITS])
  check sizeof(TEST_BITS) == sizeof(Bitset[TEST_BITS])

test "uint compatibility":
  check  emp.ord == 0b00000
  check    a.ord == 0b00001
  check    b.ord == 0b00010
  check    c.ord == 0b00100
  check   ab.ord == 0b00011
  check  abc.ord == 0b00111
  check abcd.ord == 0b10111
  check  bcd.ord == 0b10110

test "iteration":
  var bits = newSeq[TEST_BITS]()
  for bit in abcd.items:
    bits.add bit
  check bits == @[A, B, C, ABC, D]

  bits = newSeq[TEST_BITS]()
  for bit in abcd.bits:
    bits.add bit
  check bits == @[A, B, C, D]

test "bitwise ops":
  check (a or ab) == ab
  check (a or b) == ab

  check (a and ab) == a
  check (a and b) == emp

  check (not a) == bcd

  check (ab xor abc) == c

  check Bitset[TEST_BITS].all == abcd
  check Bitset[TEST_BITS].mask == 0b11111

test "equalablity":
  check abc == Bitset[TEST_BITS]{ABC}

  check a == a
  check (not (a < a))
  check a <= a
  check A in a

  check a != ab
  check a < ab
  check a <= ab
  check A in ab

  check ab == ab
  check (not (ab < ab))
  check ab <= ab

  check a != b
  check (not (a < b))
  check (not (a <= b))
  check A notin b

  check ab != abc
  check ab < abc
  check ab <= abc

  check ab != c
  check (not (ab < c))
  check (not (ab <= c))