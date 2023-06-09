import std/unittest
import std/math
import std/macros
import beyond/oop

type TEST_ENUM = enum
  teA
  teB
  teC
  MAX
type TEST_FUNC_TY = proc(int_val: int; float_val: float): TEST_ENUM {.noSideEffect.}
type TEST_LAMBDA_TY = proc(int_val: int): int

type TEST_OBJECT = object
  PROCEDURE1: proc(int_val: int)
  PROCEDURE2: TEST_LAMBDA_TY

template TEST_PRAGMA {.pragma.}

test "define proc from type":
  # TEST_FUNC_TY.genPrivateProcAs TEST_FUNC:
  TEST_FUNC_TY => TEST_FUNC:
    TEST_ENUM(floor(int_val.float * float_val).int mod TEST_ENUM.MAX.ord)
  check TEST_FUNC(2, 5) == teB

test "define lambda from type":
  # TEST_LAMBDA_TY.genLambda:
  let lambda = TEST_LAMBDA_TY => int_val * 2
  check lambda(2) == 4

# TEST_FUNC_TY.genPublicProcAs TEST_FUNC:
TEST_FUNC_TY =>* TEST_PUBLIC_FUNC:
  debugEcho "HI!"

test "define with additional pragmas":
  TEST_FUNC_TY => TEST_FUNC {.TEST_PRAGMA.}:
    discard
  check TEST_FUNC.hasCustomPragma(TEST_PRAGMA)

test "define proc from object nested":
  var PROCEDURE1_result: int
  TEST_OBJECT.PROCEDURE1 => PROCEDURE1:
    PROCEDURE1_result = int_val * 2

  TEST_OBJECT.PROCEDURE2 => PROCEDURE2:
    int_val * 2

  PROCEDURE1(10)
  check PROCEDURE1_result == 20
  check PROCEDURE2(10) == 20