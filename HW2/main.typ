#import "worksheet-template.typ": exercise, homework-header, setup

#show: setup
#homework-header(2, subtitle: [Monotone Frameworks and Dataflow Analysis])

= Monotone operators

#exercise([5.2], [
  Describe an algorithm for checking monotonicity of an operator given by an
  $n times n$ table. Can you do better than $O(n^3)$ time?
], solution: [], height: 14em)

#exercise([5.3], [
  Check that the six tables in Section 5.1 define monotone operators on the
  Sign lattice.
], solution: [], height: 14em)

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
], solution: [], height: 14em)

= Work-list complexity

#exercise([5.22], [
  Estimate the worst-case time complexity of sign analysis with the simple
  work-list algorithm, using $O(n dot h dot k)$, where $n$ is the number of CFG
  nodes, $h$ is the height of the abstract-state lattice, and $k$ is the cost
  of computing one constraint function. (As this formula applies to _any_ dataflow analysis implemented with the simple work-list algorithm, the actual worst-case complexity of this specific analysis may be asymptotically better!)
], solution: [], height: 12em)

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
], solution: [], height: 18em)
