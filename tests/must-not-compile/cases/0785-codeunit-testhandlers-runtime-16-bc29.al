// @expect AL0383 | The option value 'Anything' is not defined on field 'TestHandler'.
// @expect AL0666 | 'TestHandlers' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @from 29
// TestHandlers needs runtime 18.0 (the corpus apps use 16.0); the system enum TestHandler of BC 29 has no member called Anything.
codeunit 59990 "MNC X CU" { Subtype = Test; TestHandlers = Anything; }
