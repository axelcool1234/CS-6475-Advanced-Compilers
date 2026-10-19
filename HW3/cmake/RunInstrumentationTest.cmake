foreach(required MLIR_OPT PLUGIN INPUT)
  if(NOT DEFINED ${required})
    message(FATAL_ERROR "RunInstrumentationTest.cmake: -D${required}= is required")
  endif()
endforeach()

execute_process(
  COMMAND "${MLIR_OPT}"
          "--load-pass-plugin=${PLUGIN}"
          "--pass-pipeline=builtin.module(known-bits{instrument=true})"
          "${INPUT}"
  OUTPUT_VARIABLE instrumented
  ERROR_VARIABLE analysis
  RESULT_VARIABLE status)

if(NOT status EQUAL 0)
  message(FATAL_ERROR "instrumentation failed (${status}):\n${analysis}")
endif()

foreach(expected
    "llvm.func @__known_bits_assert"
    "llvm.icmp \"eq\""
    "llvm.call @__known_bits_assert"
    "known-bits assertion for")
  string(FIND "${instrumented}" "${expected}" position)
  if(position EQUAL -1)
    message(FATAL_ERROR "instrumented IR is missing: ${expected}")
  endif()
endforeach()

message(STATUS "known-bits: assertion instrumentation present")
