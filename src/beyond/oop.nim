## If you do not like default operators,
## please import oop_bitter module directly
## and define alternative operators.
import ./oop_bitter; export oop_bitter

template `=>`*(procdef: typedesc[proc]; name; body): untyped = genPrivateProcAs(procdef, name, body)
template `=>*`*(procdef: typedesc[proc]; name; body): untyped = genPublicProcAs(procdef, name, body)
template `=>`*(procdef: typedesc[proc]; body): untyped = genLambda(procdef, body)

template `|>`*[T](Type: typedesc[T]; item): untyped = Type.getStatic(item)