import std/sequtils
import ../macros

macro implement*(washby: typedesc[proc]; def): untyped =
  var procty = washby.getTypeImpl[1]
  if procty.kind == nnkSym:
    procty = procty.getImpl[2]

  procty.expectKind nnkProcTy

  let params = copy procty[0]
  params.expectKind nnkFormalParams
  block `Replace each symbols of FormalParams.IdentDefs.name into ident`:
    for i in (1..<params.len):
      params[i].expectKind nnkIdentDefs
      for i_def in 0..<(params[i].len-2): # identdefs: [name..., type, default]
        if params[i][i_def].kind == nnkSym:
          params[i][i_def] = ident $params[i][i_def]

  proc pragmanodes(p: NimNode): seq[NimNode] =
    p.expectKind {nnkPragma, nnkEmpty}
    case p.kind
    of nnkPragma: return p[0..^1]
    else: discard

  def[3] = params
  def[4] = nnkPragma.newTree concat(def[4].pragmanodes, procty[1].pragmanodes)
  result = def