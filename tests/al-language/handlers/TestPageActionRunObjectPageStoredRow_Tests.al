// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpageonrec-property
// Scope: in-scope
// Fixtures used: TPARPS Row (67360), TPARPS Probe (67360), TPARPS Host (67360),
//                TPARPS Target (67361), Assert (60021)
//
// The host list page's OnAfterGetRecord sets Rec.Grp := 'CALC' for every row it reads; the
// stored value of row B is 'G2' and nothing ever saves 'CALC'. A RunPageOnRec action opens the
// target card on row B. These arms pin what the target's Rec holds in OnOpenPage, what its Grp
// field shows, and what the target's own save of an edit to Descr stores in Grp.
//
// Written by agent stma-auto2-15, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 4752.

codeunit 67361 "TPARPS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EditInHandler: Boolean;

    local procedure Initialize(Edit: Boolean)
    var
        Probe: Codeunit "TPARPS Probe";
        Row: Record "TPARPS Row";
    begin
        Probe.Reset();
        EditInHandler := Edit;
        Row.DeleteAll();
        AddRow('A', 'Alpha', 'G1');
        AddRow('B', 'Bravo', 'G2');
        AddRow('C', 'Charlie', 'G1');
        Commit();
    end;

    local procedure AddRow(No: Code[20]; Descr: Text[50]; Grp: Code[10])
    var
        Row: Record "TPARPS Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Descr := Descr;
        Row.Grp := Grp;
        Row.Insert();
    end;

    local procedure OpenHostOnB(var Host: TestPage "TPARPS Host")
    var
        Row: Record "TPARPS Row";
    begin
        Host.OpenEdit();
        Row.Get('B');
        Host.GoToRecord(Row);
        Assert.AreEqual('B', Host."No.".Value(), 'precondition: the host is on row B');
        Assert.AreEqual('CALC', Host.Grp.Value(), 'precondition: the host''s OnAfterGetRecord put CALC into Rec.Grp');
    end;

    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure TargetOnOpenPageSeesHostRow()
    var
        Probe: Codeunit "TPARPS Probe";
        Host: TestPage "TPARPS Host";
    begin
        Initialize(false);
        OpenHostOnB(Host);
        Host.RunTarget.Invoke();
        Assert.AreEqual('B:CALC', Probe.GetOpenSeen(), 'what the RunPageOnRec target''s Rec holds in OnOpenPage');
        Host.Close();
    end;

    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure TargetShowsStoredGrp()
    var
        Probe: Codeunit "TPARPS Probe";
        Host: TestPage "TPARPS Host";
    begin
        Initialize(false);
        OpenHostOnB(Host);
        Host.RunTarget.Invoke();
        Assert.AreEqual('G2', Probe.GetShownGrp(), 'the Grp the RunPageOnRec target shows for row B');
        Host.Close();
    end;

    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure TargetSaveDoesNotStoreHostsComputedValue()
    var
        Probe: Codeunit "TPARPS Probe";
        Host: TestPage "TPARPS Host";
        Row: Record "TPARPS Row";
    begin
        Initialize(true);
        OpenHostOnB(Host);
        Host.RunTarget.Invoke();
        Row.Get('B');
        Assert.AreEqual('Written', Row.Descr, 'the target''s edit of Descr must reach the database');
        Assert.AreEqual('G2', Row.Grp, 'the target''s save must not store the host''s in-memory Grp');
        Assert.AreEqual('G2>G2', Probe.GetLastModify(), 'xRec.Grp>Rec.Grp in OnModify for the target''s save');
        Host.Close();
    end;

    [PageHandler]
    procedure TargetHandler(var Target: TestPage "TPARPS Target")
    var
        Probe: Codeunit "TPARPS Probe";
    begin
        Probe.RecordShownGrp(Target.Grp.Value());
        if EditInHandler then
            Target.Descr.SetValue('Written');
        Target.Close();
    end;
}
