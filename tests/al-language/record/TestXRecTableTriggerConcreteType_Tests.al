// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-overview
// Scope: in-scope
// Fixtures used: xRec Probe (60525), Assert (60021)
//
// Regression proof that inserting a record whose OnInsert trigger reads xRec
// does not throw an invalid-cast error. xRec's before-image must be built as
// the concrete record type, not a base record type, so the compiler-generated
// cast in the xRec accessor succeeds.

codeunit 60526 "Test xRec Table Trigger Type"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    trigger OnRun()
    begin
    end;

    local procedure Initialize()
    var
        Probe: Record "xRec Probe";
    begin
        Probe.DeleteAll();
    end;

    [Test]
    procedure TestTable_Insert_OnInsertReadsXRec_BuildsConcreteBeforeImage()
    var
        Probe: Record "xRec Probe";
    begin
        Initialize();

        // [GIVEN] a fresh record
        Probe.Init();
        Probe."No." := 'A1';

        // [WHEN] it is inserted with its OnInsert trigger running (which reads xRec)
        Probe.Insert(true);

        // [THEN] the trigger ran and read xRec's before-image (Counter 0 -> 1).
        // If OldRecord were built as a base record type, the xRec cast would
        // have thrown before this point.
        Probe.Get('A1');
        Assert.AreEqual(1, Probe."Counter",
            'OnInsert should have read xRec (before-image Counter = 0) and set Counter = 1');
    end;
}
