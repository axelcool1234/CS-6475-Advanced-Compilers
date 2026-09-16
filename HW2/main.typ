#import "worksheet-template.typ": exercise, homework-header, setup

#show: setup
#homework-header(2, subtitle: [Monotone Frameworks and Dataflow Analysis])

= Monotone operators

#exercise([5.2], [
  Describe an algorithm for checking monotonicity of an operator given by an
  $n times n$ table. Can you do better than $O(n^3)$ time?
], solution: [
I cannot do better than $O(n^3)$ time. Here is the algorithm:
#show raw.where(block: true): it => {
  show regex("\\$[^$]+\\$"): found => {
    eval(found.text.slice(1, -1), mode: "math")
  }
  it
}
```
bool isMonotone(table, latticeElements) {
  for x in latticeElements:
    for y in latticeElements:
      if not x $subset.eq.sq$ y:
        continue
      for z in latticeElements:
        if not table[x, z] $subset.eq.sq$ table[y, z]:
          return false
        if not table[z, x] $subset.eq.sq$ table[z, y]:
          return false
  return true
}
```
], height: 18em)

#exercise([5.3], [
  Check that the six tables in Section 5.1 define monotone operators on the
  Sign lattice.
], solution: [
#let sign-elements = range(5)
#let sign-labels = ($bot$, $0$, $-$, $+$, $top$)
#let sign-leq(x, y) = x == y or x == 0 or y == 4

#let addition = (
  (0, 0, 0, 0, 0),
  (0, 1, 2, 3, 4),
  (0, 2, 2, 4, 4),
  (0, 3, 4, 3, 4),
  (0, 4, 4, 4, 4),
)
#let subtraction = (
  (0, 0, 0, 0, 0),
  (0, 1, 3, 2, 4),
  (0, 2, 4, 2, 4),
  (0, 3, 3, 4, 4),
  (0, 4, 4, 4, 4),
)
#let multiplication = (
  (0, 0, 0, 0, 0),
  (0, 1, 1, 1, 1),
  (0, 1, 3, 2, 4),
  (0, 1, 2, 3, 4),
  (0, 1, 4, 4, 4),
)
#let division = (
  (0, 0, 0, 0, 0),
  (0, 0, 1, 1, 1),
  (0, 0, 4, 4, 4),
  (0, 0, 4, 4, 4),
  (0, 0, 4, 4, 4),
)
#let greater-than = (
  (0, 0, 0, 0, 0),
  (0, 1, 3, 1, 4),
  (0, 1, 4, 1, 4),
  (0, 3, 3, 4, 4),
  (0, 4, 4, 4, 4),
)
#let equality = (
  (0, 0, 0, 0, 0),
  (0, 3, 1, 1, 4),
  (0, 1, 4, 1, 4),
  (0, 1, 1, 4, 4),
  (0, 4, 4, 4, 4),
)

#let operators = (
  ($+$, addition),
  ($-$, subtraction),
  ($times$, multiplication),
  ("/", division),
  ($>$, greater-than),
  ("==", equality),
)

#let operator-table(name, values) = {
  let cells = (name,)
  cells += sign-labels
  for (row-number, row) in values.enumerate() {
    cells.push(sign-labels.at(row-number))
    for value in row {
      cells.push(sign-labels.at(value))
    }
  }

  set text(size: 8.5pt)
  table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: center + horizon,
    inset: (x: 3pt, y: 1.5pt),
    stroke: 0.35pt + rgb("94a3b8"),
    fill: (x, y) => if x == 0 or y == 0 { rgb("f1f5f9") },
    ..cells,
  )
}

#grid(
  columns: (1fr, 1fr),
  column-gutter: 10pt,
  row-gutter: 8pt,
  ..operators.map(operator => operator-table(
    operator.at(0),
    operator.at(1),
  )),
)

The following Typst function implements the pseudo algorithm from
Exercise 5.2:

#let checker-source = ```typc
(table, latticeElements, leq) => {
  for x in latticeElements {
    for y in latticeElements {
      if not leq(x, y) { continue }
      for z in latticeElements {
        if not leq(table.at(x).at(z), table.at(y).at(z)) {
          return false
        }
        if not leq(table.at(z).at(x), table.at(z).at(y)) {
          return false
        }
      }
    }
  }
  true
}
```
#checker-source
#let is-monotone = eval(checker-source.text, mode: "code")

#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 5pt,
  row-gutter: 5pt,
  ..operators.map(operator => {
    let name = operator.at(0)
    let result = is-monotone(operator.at(1), sign-elements, sign-leq)
    assert(result, message: "a Sign operator table is not monotone")
    box(
      width: 100%,
      inset: 4pt,
      fill: rgb("ecfdf5"),
      stroke: 0.5pt + rgb("86efac"),
      radius: 2pt,
      align(center)[#name: *monotone*],
    )
  }),
)
], height: 45em)

#pagebreak()
= Improving abstract evaluation

#exercise([5.9], [
  Show how the `eval` function could be improved to make sign analysis show
  that the final value of `z` cannot be negative in this program:

```tip
var x,y,z;
x = input;
y = x*x;
z = (x-x+1)*y;
```
], solution: [
$"eval"(sigma, X) = sigma(X)$\
$"eval"(sigma, I) = "sign"(I)$\
$"eval"(sigma, "input") = top$\
$"eval"(sigma, E_1 hat(*) E_2) = 0$ if ($"eval"(sigma, E_1) == 0$ or $"eval"(sigma, E_2) == 0$) and $"eval"(sigma, E_1) != bot$ and $"eval"(sigma, E_2) != bot$\
$"eval"(sigma, E_1 hat(*) E_2) = 0^+$ if $E_1 == E_2$ and $"eval"(sigma, E_1) != bot$ and $"eval"(sigma, E_2) != bot$\
$"eval"(sigma, E_1 hat(-) E_2) = 0$ if $E_1 == E_2$ and $"eval"(sigma, E_1) != bot$ and $"eval"(sigma, E_2) != bot$\
$"eval"(sigma, E_1 "op" E_2) = hat("op")("eval"(sigma, E_1), "eval"(sigma, E_2))$

This assumes eval is run in the order of its defined rules. Additionally, $E_1 == E_2$ means syntactic equality here.
], height: 13em)

= Work-list complexity

#exercise([5.22], [
  Estimate the worst-case time complexity of sign analysis with the simple
  work-list algorithm, using $O(n dot h dot k)$, where $n$ is the number of CFG
  nodes, $h$ is the height of the abstract-state lattice, and $k$ is the cost
  of computing one constraint function. (As this formula applies to _any_ dataflow analysis implemented with the simple work-list algorithm, the actual worst-case complexity of this specific analysis may be asymptotically better!)
], solution: [
$k$ is constant for sign analysis, and $h$ is either 3 or 5 depending on which version of the sign lattice we use. Because both of these are constant, we are left with an $O(n)$ time complexity.
], height: 4em)

#pagebreak()
= Distributivity

#exercise([5.34], [
  Which among the following analyses are distributive, if any?

  #enum(
    numbering: "(a)",
    [Available expressions.],
    [Very busy expressions.],
    [Reaching definitions.],
    [Sign analysis.],
    [Constant propagation.],
  )
], solution: [
A function $f : L_1 arrow.r L_2$ where $L_1$ and $L_2$ are lattices is _distributive_ when $forall x, y in L_1 : f (x) union.sq f(y) = f(x union.sq y)$.\

  #enum(
    numbering: "(a)",
    [Because _exps_ is always unioning for its op case, this is distributive.],
    [Same reasoning for available expressions applies here - so it is distributive.],
    [Because the lattice join is set union, it is distributive.],
    [It is not distributive. $hat(*)(-, -) union.sq hat(*)(+, +) = +$. $hat(*)(- union.sq +, - union.sq +) = top$.],
    [It is not distributive. $hat(*)(-1, -1) union.sq hat(*)(1, 1) = 1$. $hat(*)(-1 union.sq 1, -1 union.sq 1) = top$.],
  )
], height: 18em)
