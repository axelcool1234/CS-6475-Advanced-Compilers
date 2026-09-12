#import "worksheet-template.typ": exercise, homework-header, setup

#show: setup
#homework-header(1, subtitle: [Lattice Theory])

= Order and lattice operations

#exercise([4.2], [
  Prove that if $x union.sq y$ exists, then
  $x subset.eq.sq y arrow.l.r.double x union.sq y = y$, and conversely, if
  $x inter.sq y$ exists, then
  $x subset.eq.sq y arrow.l.r.double x inter.sq y = x$.
], solution: [], height: 14em)

#exercise([4.6], [
  Why do the following two Hasse diagrams not define lattices?

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 2em,
    align: center,
    [
```text
●     ●     ●
 ╲   ╱ ╲   ╱
   ●     ●
    ╲   ╱
      ●
```
    ],
    [
```text
      ●
    ╱   ╲
   ●     ●
   │╲   ╱│
   ● ╱ ╲ ●
    ╲   ╱
      ●
```
    ],
  )
], solution: [], height: 10em)

#pagebreak()
= Fixed points

#exercise([4.30], [
  Explain step-by-step how the naive fixed-point algorithm computes the
  solution to the equation system from Exercise 4.16:

  $ x_1 = [a arrow.r top, b arrow.r top] $

  $ x_2 = x_1[a arrow.r +] $

  $ x_3 = x_2[b arrow.r x_2(a) + top] $

  $ x_4 = x_3[a arrow.r x_3(a) - x_3(b)]. $
], solution: [], height: 22em)

#exercise([4.32], [
  Does the fixed-point theorem also hold without the assumption that the
  lattice has finite height? If yes, give a proof; if no, give a counterexample.
], solution: [], height: 12em)
