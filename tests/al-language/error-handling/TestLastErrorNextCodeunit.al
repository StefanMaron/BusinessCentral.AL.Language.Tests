// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Assert
//
// Cross-codeunit variant of "Test LastError Across Tests" (69990), whose last test traps
// 'ALT-LE-CARRY-C': this codeunit's only test reads the last error as its first statement.
// If the value is not empty, the failure message names it, which says which test left it.
// For StefanMaron/BusinessCentral.AL.Runner#5057.

codeunit 69991 "Test LastError Next Codeunit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure FirstTest_GetLastErrorText_IsEmpty()
    var
        Text: Text;
    begin
        // Read before Initialize(): nothing of this test may touch the last error first.
        Text := GetLastErrorText();
        Cleanup.Initialize();
        Assert.AreEqual('', Text, 'GetLastErrorText at the start of the first test method of a codeunit');
    end;
}
