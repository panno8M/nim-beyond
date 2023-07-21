## If you do not like default operators,
## please import oop_bitter module directly
## and define alternative operators.
import ./oop_bitter; export oop_bitter

template `|>`*[T](Type: typedesc[T]; item): untyped = Type.getStatic(item)