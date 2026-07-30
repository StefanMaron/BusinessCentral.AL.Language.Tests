// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: "Record Get NotFound Row" (60386)
//
// Record.Get must raise when the row does not exist and the caller does not consume the
// return value. AL picks the failure mode from the call site: `if Rec.Get(x) then` traps
// the error and yields false, while a bare `Rec.Get(x);` statement raises. A Get that
// silently succeeds on the raising form leaves the caller holding a blank or stale
// record, and every assertion after it is then testing something that never happened.

codeunit 60387 "Test Record Get NotFound"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure SeedRow(No: Code[20]; Description: Text[50])
    var
        Row: Record "Record Get NotFound Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Description := Description;
        Row.Insert();
    end;

    [Test]
    procedure Record_GetMissingRow_AsStatement_Raises()
    var
        Row: Record "Record Get NotFound Row";
    begin
        Initialize();
        SeedRow('EXISTS-1', 'seeded');

        // The return value is deliberately not consumed, so this must raise rather than
        // leave Row holding whatever it held before.
        asserterror Row.Get('MISSING-1');
        Assert.ExpectedErrorCannotFind(Database::"Record Get NotFound Row");
    end;

    [Test]
    procedure Record_GetMissingRow_DoesNotLeaveStaleDataBehind()
    var
        Row: Record "Record Get NotFound Row";
    begin
        Initialize();
        SeedRow('EXISTS-1', 'seeded');

        Row.Get('EXISTS-1');
        Assert.AreEqual('seeded', Row.Description, 'Precondition: reading the existing row must give ''seeded''.');

        // The failed Get must not silently succeed and hand back the PREVIOUS row's
        // contents. This is the concrete damage a silently-succeeding Get does: the
        // caller reads 'seeded' for a key that was never there.
        asserterror Row.Get('MISSING-1');
        Assert.ExpectedErrorCannotFind(Database::"Record Get NotFound Row");
    end;

    [Test]
    procedure Record_GetMissingRow_WhenReturnValueConsumed_ReturnsFalseAndDoesNotRaise()
    var
        Row: Record "Record Get NotFound Row";
        Found: Boolean;
    begin
        Initialize();
        SeedRow('EXISTS-1', 'seeded');

        // The other direction: consuming the result traps the error. A fix that made
        // every Get raise unconditionally would break this.
        Found := Row.Get('MISSING-1');
        Assert.IsFalse(Found, 'Get on a missing row must return false when the result is consumed.');

        Found := Row.Get('EXISTS-1');
        Assert.IsTrue(Found, 'Get on an existing row must return true.');
        Assert.AreEqual('seeded', Row.Description, 'Get on an existing row must load the real content.');
    end;

    local procedure Initialize()
    var
        Row: Record "Record Get NotFound Row";
    begin
        Row.DeleteAll();
    end;
}
