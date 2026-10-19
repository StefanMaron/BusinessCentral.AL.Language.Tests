// @expect AL0223 | The Property 'TestType' can only be used if the property 'Subtype' is set to 'Test'
// TestType is only allowed on a codeunit with Subtype = Test.
codeunit 59990 "MNC X CU" { TestType = IntegrationTest; }
