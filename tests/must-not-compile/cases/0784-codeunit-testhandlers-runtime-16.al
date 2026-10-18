// @expect AL0928 | Could not find the system Enum TestHandler with ID '2000000023'. Ensure that you have downloaded the latest System symbols.
// @expect AL0666 | 'TestHandlers' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @until 27
// TestHandlers needs runtime 18.0 (the corpus apps use 16.0); the BC 27 symbols also lack the system enum TestHandler.
codeunit 59990 "MNC X CU" { Subtype = Test; TestHandlers = Anything; }
