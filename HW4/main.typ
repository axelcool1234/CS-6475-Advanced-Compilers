#import "../worksheet-template.typ": homework-header, setup

#show: setup
#homework-header(4, subtitle: [Dynamic Soundness Checking for MLIR Dataflow Analysis])

#let placeholder(body, height: 7em) = block(
  width: 100%,
  height: height,
  breakable: false,
  inset: 9pt,
  fill: rgb("f8fafc"),
  stroke: 0.6pt + rgb("cbd5e1"),
  radius: 3pt,
  text(fill: rgb("64748b"), style: "italic", body),
)

= Overview

#placeholder([Summarize the analysis, the checking approach, and the outcome.])

= Turning dataflow facts into assertions

#placeholder([Describe the abstract fact and the equivalent runtime predicate.], height: 10em)

= MLIR instrumentation

#placeholder([Show and explain the relevant original and instrumented MLIR.], height: 12em)

= Experimental setup and inputs

#placeholder([Describe the lowering/linking pipeline and the tested inputs.], height: 9em)

= Triggering MLIR program

#placeholder([Include the reduced MLIR file that exposes the soundness bug.], height: 15em)

= Observed failure

#placeholder([Record the failing input and assertion diagnostic.], height: 9em)

= Analysis bug

#placeholder([Explain the incorrect transfer behavior and state whether it was pre-existing or deliberately inserted.], height: 11em)

= Conclusion

#placeholder([Briefly summarize what dynamic checking established.])
