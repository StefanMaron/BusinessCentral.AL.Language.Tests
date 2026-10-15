// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Assert
//
// Does the last error one [Test] method trapped reach the next [Test] method? TestGetLastError.al
// clears it in every test, so it never measured this. A traps an error; B, declared next in the
// same codeunit, reads GetLastErrorText / GetLastErrorCode / GetLastErrorCallStack BEFORE anything
// of its own can set or clear it. The cross-codeunit variant is "Test LastError Next Codeunit"
// (69991), which reads it as its first statement after this codeunit's last test trapped one.
// For StefanMaron/BusinessCentral.AL.Runner#5057.

codeunit 69990 "Test LastError Across Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure A_TrapsAnError_LastErrorIsSetInsideTheTest()
    begin
        Initialize();
        asserterror Error('ALT-LE-CARRY-A');
        Assert.AreEqual('ALT-LE-CARRY-A', GetLastErrorText(), 'the trapped error must be the last error inside the test that trapped it');
    end;

    [Test]
    procedure B_NextTest_GetLastErrorText_IsEmpty()
    var
        Text: Text;
        Code: Text;
        CallStack: Text;
    begin
        // Read before Initialize(): nothing of this test may touch the last error first.
        Text := GetLastErrorText();
        Code := GetLastErrorCode();
        CallStack := GetLastErrorCallStack();
        Initialize();
        Assert.AreEqual('', Text, 'GetLastErrorText at the start of the next test method');
        Assert.AreEqual('', Code, 'GetLastErrorCode at the start of the next test method');
        Assert.AreEqual('', CallStack, 'GetLastErrorCallStack at the start of the next test method');
    end;

    [Test]
    procedure C_TrapsAnErrorForTheNextCodeunit()
    begin
        Initialize();
        asserterror Error('ALT-LE-CARRY-C');
        Assert.AreEqual('ALT-LE-CARRY-C', GetLastErrorText(), 'the trapped error must be the last error inside the test that trapped it');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
