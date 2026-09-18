// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-truncate-method
// Scope: in-scope
// Fixtures used: "ALT Universal" (table 60000), "ALT Truncate Try Helper" (codeunit 60924)
// BC versions: 24+

/// <summary>
/// Record.Truncate() is refused inside a try function, and allowed outside one.
///
/// BC's NavRecord.ValidateTruncateSupport reads
/// Session.CurrentMethodScope.IsInTryScope and raises Lang.TruncateTryFunction —
/// "Truncate is not supported in try functions." — when it is set. The flag reaches a
/// nested frame only because NavMethodScope's constructor ORs it in from the parent scope,
/// so the three tests below separate the inherited case from the direct one.
///
/// "ALT Universal" is chosen deliberately: ValidateTruncateSupport runs six OTHER guards
/// around the one under test, and each raises its own distinct message. The table is a
/// normal, non-system, non-temporary table with no Media/MediaSet fields and no
/// OnBeforeDelete/OnAfterDelete subscribers, so it clears all six. Every assertion below is
/// on the MESSAGE rather than on the mere fact that something threw, because a fixture that
/// tripped one of the other guards would otherwise look like a pass.
/// </summary>
codeunit 60923 "Test Record Truncate Try"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        TruncateInTryErr: Label 'Truncate is not supported in try functions.', Locked = true;

    [Test]
    procedure Truncate_NestedInsideATryFunction_IsRefused()
    // CLAIM: a frame CALLED FROM a try function is itself in the try scope, so Truncate()
    // there raises the try-function refusal. The truncating frame is the helper codeunit's
    // procedure, one call below the [TryFunction] — it is not a try function itself, so it
    // can only see IsInTryScope if the scope it was constructed under passed the flag down.
    // This is the arm that fails against an implementation which sets the flag on literal
    // try frames alone.
    var
        Universal: Record "ALT Universal";
    begin
        Initialize();
        SeedOneRow();

        ClearLastError();

        // Act — the try function calls the helper, and the helper truncates.
        if TryTruncateViaHelper() then
            Assert.IsTrue(false, 'Truncate() nested inside a try function must not succeed');

        // Assert — BC's try-function refusal, by message, not merely "something failed".
        Assert.AreEqual(
            TruncateInTryErr,
            GetLastErrorText(),
            'Truncate() below a try function must raise the try-function refusal');

        // The table is untouched: the refusal happens in validation, before any rows go.
        Assert.AreEqual(1, Universal.Count(), 'A refused Truncate() must not delete rows');
    end;

    [Test]
    procedure Truncate_DirectlyInsideATryFunction_IsRefused()
    // CLAIM: the control for the test above. Here Truncate() runs in the try function's OWN
    // frame, which carries IsInTryScope whether or not the flag is inherited by children.
    // Kept deliberately: it holds the surrounding claim — that a try scope refuses Truncate
    // at all — fixed while the nested test varies only the DEPTH of the frame. If this one
    // passes and the nested one fails, the defect is specifically the inheritance and not
    // Truncate-in-a-try-scope generally.
    var
        Universal: Record "ALT Universal";
    begin
        Initialize();
        SeedOneRow();

        ClearLastError();

        if TryTruncateDirectly() then
            Assert.IsTrue(false, 'Truncate() directly inside a try function must not succeed');

        Assert.AreEqual(
            TruncateInTryErr,
            GetLastErrorText(),
            'Truncate() in a try function''s own frame must raise the try-function refusal');

        Assert.AreEqual(1, Universal.Count(), 'A refused Truncate() must not delete rows');
    end;

    [Test]
    procedure Truncate_OutsideAnyTryFunction_Succeeds()
    // CLAIM: the negative half of the pair. Without it, a runner (or a tier) that refused
    // Truncate() EVERYWHERE would pass both tests above. The same table, the same seeded
    // row, and the same call through the same helper — the only thing that changes is that
    // no try function is on the stack — and here the rows actually go.
    var
        Universal: Record "ALT Universal";
        Helper: Codeunit "ALT Truncate Try Helper";
    begin
        Initialize();
        SeedOneRow();

        ClearLastError();

        // Act — the identical helper call, with no try function anywhere on the stack.
        Helper.TruncateUniversal();

        // Assert — it worked, and nothing was raised.
        Assert.AreEqual('', GetLastErrorText(), 'Truncate() outside a try function must not raise');
        Assert.IsTrue(Universal.IsEmpty(), 'Truncate() outside a try function must empty the table');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure SeedOneRow()
    var
        Universal: Record "ALT Universal";
    begin
        // Seeded OUTSIDE any try function on purpose: BC refuses INSERT inside a
        // [TryFunction] when RunTests is on the call stack (see TestTryFunctionContracts.al).
        Universal."Entry No." := 1;
        Universal."Integer Field" := 10;
        Universal.Insert();
    end;

    [TryFunction]
    local procedure TryTruncateViaHelper()
    var
        Helper: Codeunit "ALT Truncate Try Helper";
    begin
        // The Truncate() itself happens one frame deeper, in the helper.
        Helper.TruncateUniversal();
    end;

    [TryFunction]
    local procedure TryTruncateDirectly()
    var
        Universal: Record "ALT Universal";
    begin
        Universal.Truncate();
    end;
}
