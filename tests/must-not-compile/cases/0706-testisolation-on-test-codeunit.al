// @expect AL0223 | The Property 'TestIsolation' can only be used if the property 'Subtype' is set to 'TestRunner'
// TestIsolation is a property of a test runner codeunit; a test codeunit cannot state it.
codeunit 59706 "MNC U Test 706" { Subtype = Test; TestIsolation = Function; [Test] procedure T() begin end; }
