import std/unittest
import std/math
import beyond/procsugar

type TEST_ENUM = enum
  teA
  teB
  teC
  MAX
type TEST_FUNC_TY = proc(int_val: int; float_val: float): TEST_ENUM {.noSideEffect.}
type TEST_LAMBDA_TY = proc(int_val: int): int

test "define proc from type":
  # TEST_FUNC_TY.genPrivateProcAs TEST_FUNC:
  TEST_FUNC_TY -> TEST_FUNC:
    TEST_ENUM(floor(int_val.float * float_val).int mod TEST_ENUM.MAX.ord)
  check TEST_FUNC(2, 5) == teB

test "define lambda from type":
  # TEST_LAMBDA_TY.genLambda:
  let lambda = TEST_LAMBDA_TY => int_val * 2
  check lambda(2) == 4

# TEST_FUNC_TY.genPublicProcAs TEST_FUNC:
TEST_FUNC_TY +> TEST_PUBLIC_FUNC:
  debugEcho "HI!"