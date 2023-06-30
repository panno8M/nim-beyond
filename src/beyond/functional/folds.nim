import ./[ macros, ]

template all*[N: static int; T](s: array[N, T]; pred): bool =
  var result = true
  for i {.inject.} in 0..<N:
    let
      a {.inject, used.} : T = s[i]
    if not pred:
      result = false
      break
  result
template all*[N: static int; T,S](s: (array[N,T], array[N,S]); pred): bool =
  var result = true
  for i {.inject.} in 0..<N:
    let
      a {.inject, used.} : T = s[0][i]
      b {.inject, used.} : S = s[1][i]
    if not pred:
      result = false
      break
  result

template any*[N: static int; T](s: array[N, T]; pred): bool =
  var result = false
  for i {.inject.} in 0..<N:
    let
      a {.inject, used.} : T = s[i]
    if pred:
      result = true
      break
  result
template any*[N: static int; T,S](s: (array[N,T], array[N,S]); pred): bool =
  var result = false
  for i {.inject.} in 0..<N:
    let
      a {.inject, used.} : T = s[0][i]
      b {.inject, used.} : S = s[1][i]
    if pred:
      result = true
      break
  result