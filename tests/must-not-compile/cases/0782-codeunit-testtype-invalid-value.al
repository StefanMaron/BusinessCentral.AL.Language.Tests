// @expect AL0169 | The option value 'Smoke' is not valid. Check the enum definition for valid values.
// TestType takes UnitTest, IntegrationTest, Uncategorized or AITest.
codeunit 59990 "MNC X CU" { Subtype = Test; TestType = Smoke; }
