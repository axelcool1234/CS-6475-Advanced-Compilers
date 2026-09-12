#let answer(body, height: 8em) = {
  block(
    width: 100%,
    height: height,
    breakable: false,
    inset: 9pt,
    fill: rgb("f8fafc"),
    stroke: 0.6pt + rgb("cbd5e1"),
    radius: 3pt,
    body,
  )
}

#let exercise(number, prompt, solution: [], height: 8em) = {
  block(
    width: 100%,
    breakable: false,
    above: 0.9em,
    below: 0.8em,
    [
      #grid(
        columns: (auto, 1fr),
        column-gutter: 0.6em,
        [#strong[Exercise #number:]],
        [#prompt],
      )
      #v(0.4em)
      #answer(height: height)[#solution]
    ],
  )
}

#let homework-header(number, subtitle: none) = {
  block(width: 100%)[
    #align(center)[
      #text(20pt, weight: "bold")[CS 6475: Advanced Compilers]
      #v(0.25em)
      #underline[#text(16pt, weight: "bold")[Homework #number]]
      #if subtitle != none {
        v(0.2em)
        text(11pt, weight: "bold")[#subtitle]
      }
    ]
  ]
  v(0.8em)
}

#let setup(body) = {
  set page(
    paper: "us-letter",
    margin: (x: 0.78in, y: 0.68in),
    numbering: "1",
    number-align: center + bottom,
  )
  set text(font: "Libertinus Serif", size: 10.5pt)
  set par(justify: true, leading: 0.62em)
  set heading(numbering: "1.")
  set list(indent: 1.2em, body-indent: 0.55em)
  show heading.where(level: 1): set text(size: 13pt, weight: "bold")
  show raw.where(block: true): it => block(
    width: 100%,
    breakable: false,
    inset: 8pt,
    fill: rgb("f5f5f5"),
    stroke: 0.5pt + rgb("d4d4d4"),
    radius: 3pt,
    text(font: "DejaVu Sans Mono", size: 8.5pt, it),
  )
  body
}
