// @expect AL0223 | The Property 'RequiredTestIsolation' can only be used if the property 'Subtype' is set to 'Test'
// RequiredTestIsolation is only allowed on a codeunit with Subtype = Test.
codeunit 59990 "MNC X CU" { RequiredTestIsolation = Function; }
