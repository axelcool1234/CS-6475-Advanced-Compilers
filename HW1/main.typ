#import "worksheet-template.typ": exercise, homework-header, setup

#show: setup
#homework-header(1, subtitle: [Lattice Theory])

= Order and lattice operations

#exercise([4.2], [
  Prove that if $x union.sq y$ exists, then
  $x subset.eq.sq y arrow.l.r.double x union.sq y = y$.
], solution: [
reflexivity: $forall x in S : x subset.eq.sq x$\
transitivity: $forall x, y, z in S : x subset.eq.sq y and y subset.eq.sq z arrow.r.double.long x subset.eq.sq z$\
anti-symmetry: $forall x, y in S : x subset.eq.sq y and y subset.eq.sq x arrow.r.double.long x = y$\
$X subset.eq.sq union.sq.big X and forall y in S : X subset.eq.sq y arrow.r.double.long union.sq.big X subset.eq.sq y$\
$inter.sq.big X subset.eq.sq X and forall y in S : y subset.eq.sq X arrow.r.double.long y subset.eq.sq inter.sq.big X$\

Least Upper Bound (LUB):\
Given that $x union.sq y$ exists:\
- ${x, y} subset.eq.sq union.sq.big {x, y} and (forall z in S : {x, y} subset.eq.sq z arrow.r.double.long union.sq.big {x, y} subset.eq.sq z)$\
- ${x, y} subset.eq.sq x union.sq y and (forall z in S : {x, y} subset.eq.sq z arrow.r.double.long x union.sq y subset.eq.sq z)$\
- $x subset.eq.sq x union.sq y and y subset.eq.sq x union.sq y and (forall z in S : x subset.eq.sq z and y subset.eq.sq z arrow.r.double.long x union.sq y subset.eq.sq z)$\

Proving:
- $x subset.eq.sq y arrow.r.double x union.sq y = y$
  - Assuming $x subset.eq.sq y$, we must prove $x union.sq y = y$
  - We currently know:
    - $x subset.eq.sq y$
    - $x subset.eq.sq x union.sq y$
    - $y subset.eq.sq x union.sq y$
    - $(forall z in S : x subset.eq.sq z and y subset.eq.sq z arrow.r.double.long x union.sq y subset.eq.sq z)$\
  - Since we can make $z$ anything, let's make it $y$: $x subset.eq.sq y and y subset.eq.sq y arrow.r.double.long x union.sq y subset.eq.sq y$
    - We know $x subset.eq.sq y$
    - We know $y subset.eq.sq y$ via reflexivity
    - Thus we know $x union.sq y subset.eq.sq y$
  - Since we know $x union.sq y subset.eq.sq y$ and $y subset.eq.sq x union.sq y$, using anti-symmetry we know that $x union.sq y = y$ 
- $x union.sq y = y arrow.r.double x subset.eq.sq y$
  - Assuming $x union.sq y = y$, we must prove $x subset.eq.sq y$
  - We currently know:
    - $x union.sq y = y$
    - $x subset.eq.sq x union.sq y$
    - $y subset.eq.sq x union.sq y$
    - $(forall z in S : x subset.eq.sq z and y subset.eq.sq z arrow.r.double.long x union.sq y subset.eq.sq z)$\
  - Since $y = x subset.eq.sq y$, we can substitute $y$ in $x subset.eq.sq x union.sq y$ to get $x subset.eq.sq y$
$qed$
], height: 45em)
#exercise([4.2], [
  Prove that if $x inter.sq y$ exists, then
  $x subset.eq.sq y arrow.l.r.double x inter.sq y = x$.
], solution: [

reflexivity: $forall x in S : x subset.eq.sq x$\
transitivity: $forall x, y, z in S : x subset.eq.sq y and y subset.eq.sq z arrow.r.double.long x subset.eq.sq z$\
anti-symmetry: $forall x, y in S : x subset.eq.sq y and y subset.eq.sq x arrow.r.double.long x = y$\
$X subset.eq.sq union.sq.big X and forall y in S : X subset.eq.sq y arrow.r.double.long union.sq.big X subset.eq.sq y$\
$inter.sq.big X subset.eq.sq X and forall y in S : y subset.eq.sq X arrow.r.double.long y subset.eq.sq inter.sq.big X$\

Greatest Lower Bound (GLB):\
Given that $x inter.sq y$ exists:
- $inter.sq.big {x, y} subset.eq.sq {x, y} and (forall z in S : z subset.eq.sq {x, y} arrow.r.double.long z subset.eq.sq inter.sq.big {x, y})$\
- $x inter.sq y subset.eq.sq {x, y} and (forall z in S : z subset.eq.sq {x, y} arrow.r.double.long z subset.eq.sq x inter.sq y)$\
- $x inter.sq y subset.eq.sq x and x inter.sq y subset.eq.sq y and (forall z in S : z subset.eq.sq x and z subset.eq.sq y arrow.r.double.long z subset.eq.sq x inter.sq y)$\

Proving:\
- $x subset.eq.sq y arrow.r.double x inter.sq y = x$
  - Assuming $x subset.eq.sq y$, we must prove $x inter.sq y = x$
  - We know:
    - $x subset.eq.sq y$
    - $x inter.sq y subset.eq.sq x$\
    - $x inter.sq y subset.eq.sq y$\
    - $(forall z in S : z subset.eq.sq x and z subset.eq.sq y arrow.r.double.long z subset.eq.sq x inter.sq y)$\
  - Since we can make $z$ anything, let's make it $x$: $x subset.eq.sq x and x subset.eq.sq y arrow.r.double.long x subset.eq.sq x inter.sq y$\
    - We know $x subset.eq.sq x$ via reflexivity
    - We know $x subset.eq.sq y$
    - Thus we know $x subset.eq.sq x inter.sq y$
  - Since we know $x inter.sq y subset.eq.sq x$ and $x subset.eq.sq x inter.sq y$, using anti-symmetry we know $x inter.sq y = x$
- $x inter.sq y = x arrow.r.double x subset.eq.sq y$
  - Assuming $x inter.sq y = x$, we must prove $x subset.eq.sq y$
  - We know:
    - $x inter.sq y = x$
    - $x inter.sq y subset.eq.sq x$\
    - $x inter.sq y subset.eq.sq y$\
    - $(forall z in S : z subset.eq.sq x and z subset.eq.sq y arrow.r.double.long z subset.eq.sq x inter.sq y)$\
  - Since $x = x inter.sq y$, we can substitute $x$ in $x inter.sq y subset.eq.sq y$ to get $x subset.eq.sq y$
$qed$
], height: 45em)

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
], solution: [
The first is missing a least upper bound for the top three nodes. For the second, the two nodes above the bottom element is missing a least upper bound.
], height: 4em)

#pagebreak()
= Fixed points

#exercise([4.30], [
  Explain step-by-step how the naive fixed-point algorithm computes the
  solution to the equation system from Exercise 4.16:

  $ x_1 = [a arrow.r top, b arrow.r top] $

  $ x_2 = x_1[a arrow.r +] $

  $ x_3 = x_2[b arrow.r x_2(a) + top] $

  $ x_4 = x_3[a arrow.r x_3(a) - x_3(b)]. $
], solution: [
#show raw.where(block: true): it => {
  show regex("\\$[^$]+\\$"): found => {
    eval(found.text.slice(1, -1), mode: "math")
  }
  it
}
```
procedure NaiveFixedPointAlgorithm(f)
  $x_1$, $x_2$, $x_3$, $x_4$ := [a $arrow.r bot$, b $arrow.r bot$]
  while $x_1$, $x_2$, $x_3$, $x_4$ $!=$ f($x_1$, $x_2$, $x_3$, $x_4$) do
    $x_1$, $x_2$, $x_3$, $x_4$ := f($x_1$, $x_2$, $x_3$, $x_4$)
  end while
  return $x_1$, $x_2$, $x_3$, $x_4$
end procedure

procedure f($x_1$, $x_2$, $x_3$, $x_4$)
  return
  (
    [a $arrow.r top$, b $arrow.r top$]
    $x_1$[a $arrow.r$ +]
    $x_2$[b $arrow.r$ $x_2$(a) + $top$]
    $x_3$[a $arrow.r$ $x_3$(a) - $x_3$(b)].
  )
end procedure
```
Step 1:
  - $x_1 = [a arrow.r top, b arrow.r top]$
  - $x_2 = [a arrow.r +, b arrow.r bot]$
  - $x_3 = [a arrow.r bot, b arrow.r bot]$
  - $x_4 = [a arrow.r bot, b arrow.r bot].$
Step 2:
  - $x_1 = [a arrow.r top, b arrow.r top]$
  - $x_2 = [a arrow.r +, b arrow.r top]$
  - $x_3 = [a arrow.r +, b arrow.r top]$
  - $x_4 = [a arrow.r bot, b arrow.r bot]$
Step 3:
  - $x_1 = [a arrow.r top, b arrow.r top]$
  - $x_2 = [a arrow.r +, b arrow.r top]$
  - $x_3 = [a arrow.r +, b arrow.r top]$
  - $x_4 = [a arrow.r top, b arrow.r top]$
On step 4, they all stay the same, which means it has reached a fixpoint.
], height: 45em)

#exercise([4.32], [
  Does the fixed-point theorem also hold without the assumption that the
  lattice has finite height? If yes, give a proof; if no, give a counterexample.
], solution: [
Kleene's fixed point theorem:\
- In a lattice $L$ with finite height, every monotone function $f : L arrow.r L$ has a unique least fixed point denoted $"lfp"(f)$ defined as $"lfp"(f) = union.sq.big_(i >= 0) f^i (bot)$\

In Kleene's fixed point theorem, it requires the lattice to have finite height.

Tarski's fixed point theorem:\
- In a complete lattice $L$, every monotone function $f : L arrow.r L$ has a unique least fixed point given by $"lfp"(f) = inter.sq.big { x in L | f(x) subset.eq.sq x}$.

In Tarski's fixed point theorem, it does not require the lattice to have finite height.\

This means it ultimately depends on which you use. If we use Kleene's without the assumption of finite height, we can define a lattice where $bot$ has an edge to $0$, $0$ has an edge to $1$, etc. The first infinite ordinal, $omega$, has an edge to $omega + 1$. If we define the transfer funciton as $f(x) = "if" x == omega + 1 "then" omega + 1 "else" x + 1$, then we face an issue:
- $union.sq.big_(i >= 0) f^i (bot) == omega$
- However, $f(omega) = omega + 1$
It didn't reach a fixpoint via finite iteration. So Kleene's fixed point theorem does not hold.
], height: 23em)
