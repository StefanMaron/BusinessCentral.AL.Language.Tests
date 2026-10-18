// @expect AL0243 | Attribute TestPermissions can only be used within a codeunit of subtype Test.
// The TestPermissions attribute on a procedure of a codeunit that is not a test codeunit.
codeunit 59050 "MNC TestPerm 0978"
{
    [TestPermissions(TestPermissions::Disabled)]
    procedure Run1()
    begin
    end;
}
