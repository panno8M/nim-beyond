import beyond/statements

echo do:
  `paragraph/`:
    text "hello!"
    `indent/` indent= 2:
      `option/` eval= true:
        `nimComment/` execute= true:
          text "XXX"
        `nimDocComment/` execute= true:
          "XXX"
        `indent/` indent= 2:
          `nimComment/` execute= true:
            "A"
            "B"
            `underline/` style= "-*-":
              `oneline/`:
                "C"
                "D"
                "E"
                oneline("F", "G", "H", "I", "J")
