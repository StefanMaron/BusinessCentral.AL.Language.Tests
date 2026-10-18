// @expect AL0132 | 'TestPermissions' does not contain a definition for 'Normal'
// TestPermissions has Disabled, Restrictive, NonRestrictive and InheritFromTestRunner; there is no Normal.
codeunit 59055 "MNC TestPermNormal 0979"
{
    Subtype = Test;

    [Test]
    [TestPermissions(TestPermissions::Normal)]
    procedure Run1()
    begin
    end;
}
