// @expect AL0169 | The option value 'Always' is not valid. Check the enum definition for valid values.
// RequiredTestIsolation takes None, Disabled, Codeunit or Function.
codeunit 59990 "MNC X CU" { Subtype = Test; RequiredTestIsolation = Always; }
