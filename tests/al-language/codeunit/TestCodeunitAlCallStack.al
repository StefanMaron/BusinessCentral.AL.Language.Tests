// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/getlasterrorcallstack-method
// Scope: in-scope
// Fixtures used: none (self-contained helper codeunit)
// BC versions: 24+

codeunit 60211 "Test Codeunit Al Call Stack"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CallStack_AfterAssertError_ContainsALFrames()
    var
        Stack: Text;
    begin
        // Arrange — call a procedure that raises an AL error through a helper
        asserterror RaiseViaHelper();

        // Act — retrieve the call stack
        Stack := GetLastErrorCallStack();

        // Assert — the frame for THIS codeunit must appear with its object ID
        // (60211) and the mandatory app-tail tokens.
        Assert.IsTrue(
            Stack.Contains('(CodeUnit 60211)'),
            'Call stack must contain "(CodeUnit 60211)". Actual stack: ' + Stack);

        Assert.IsTrue(
            Stack.Contains(' by '),
            'Call stack must contain the " by " publisher token');

        Assert.IsTrue(
            Stack.Contains(' version '),
            'Call stack must contain the " version " token from app.json');

        // The helper frame must also appear with its object ID (60212)
        Assert.IsTrue(
            Stack.Contains('(CodeUnit 60212)'),
            'Call stack must contain "(CodeUnit 60212)" for the helper codeunit');

        // Every frame must include a line number
        Assert.IsTrue(
            Stack.Contains(' line '),
            'Call stack must contain " line " (AL source line numbers)');
    end;

    [Test]
    procedure CallStack_WhenNoError_ReturnsEmpty()
    var
        Stack: Text;
    begin
        Initialize();
        // No error was raised in THIS test — GetLastErrorCallStack must return
        // empty / blank. Explicitly clear first: BC does not reset the
        // last-error call stack between [Test] methods in the same codeunit
        // run, so a prior test's asserterror (e.g.
        // CallStack_AfterAssertError_ContainsALFrames) would otherwise leak
        // its stack into this assertion.
        ClearLastError();
        Stack := GetLastErrorCallStack();
        Assert.AreEqual('', Stack, 'GetLastErrorCallStack must be empty when no error occurred');
    end;

    local procedure Initialize()
    begin
    end;

    local procedure RaiseViaHelper()
    var
        Helper: Codeunit "AL Call Stack Helper";
    begin
        Helper.RaiseError();
    end;
}
