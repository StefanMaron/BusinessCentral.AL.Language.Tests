// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-asserterror-statement
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021);
//                self-contained table 68240, page 68242 and codeunit 68241
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins what a Validate that raises leaves on the record (the whole record goes back to its values
// from before the Validate, not just the validated field), how a chained Validate and a direct
// assignment inside a trigger behave, and how far an asserterror inside a modal page handler rolls
// the database back (to the last Commit: the writes made before the page opened and the handler's
// own writes are all lost).
// BC versions: 27.5

table 68240 "Probe Validate Rollback"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Text[20])
        {
            trigger OnValidate()
            begin
                B := 'set-by-A-trigger';
                C := C + 1;
                if A = 'bad' then
                    Error('A rejected');
            end;
        }
        field(3; B; Text[20]) { }
        field(4; C; Integer) { }
        field(5; D; Text[20])
        {
            trigger OnValidate()
            begin
                A := 'set-A-direct';
                Validate(B, 'chained');
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 68242 "Probe AH Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;
}

codeunit 68241 "Probe Validate Rollback Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Validate_ThatRaises_RestoresTheWholeRecord()
    // CLAIM: after the error A, B and C hold their values from before the Validate; the changes the trigger made to B and C are undone too.
    var
        Rec: Record "Probe Validate Rollback";
    begin
        Rec.Id := 1;
        Rec.A := 'old';
        Rec.B := 'orig-B';
        Rec.C := 10;

        asserterror Rec.Validate(A, 'bad');

        Assert.AreEqual('A rejected', GetLastErrorText(), 'text');
        Assert.AreEqual('Dialog', GetLastErrorCode(), 'code');
        Assert.AreEqual('old', Rec.A, 'the validated field');
        Assert.AreEqual('orig-B', Rec.B, 'a field the trigger set');
        Assert.AreEqual(10, Rec.C, 'a field the trigger incremented');
    end;

    [Test]
    procedure Validate_ThatSucceeds_KeepsWhatTheTriggerChanged_AndAssignmentInATriggerRunsNoTrigger()
    var
        Rec: Record "Probe Validate Rollback";
    begin
        Rec.Id := 1;
        Rec.A := 'old';
        Rec.B := 'orig-B';
        Rec.C := 10;

        Rec.Validate(A, 'good');
        Assert.AreEqual('good', Rec.A, 'A');
        Assert.AreEqual('set-by-A-trigger', Rec.B, 'B');
        Assert.AreEqual(11, Rec.C, 'C');

        Rec.A := 'old';
        Rec.B := 'orig-B';
        Rec.C := 10;
        Rec.Validate(D, 'dval');
        Assert.AreEqual('set-A-direct', Rec.A, 'D''s trigger assigned A directly: A''s trigger did not run');
        Assert.AreEqual('chained', Rec.B, 'D''s trigger validated B');
        Assert.AreEqual(10, Rec.C, 'so C was not incremented');
        Assert.AreEqual('dval', Rec.D, 'D');
    end;

    local procedure Cnt(EntryNo: Integer): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.SetRange("Entry No.", EntryNo);
        exit(ALTUniversal.Count());
    end;

    [Test]
    [HandlerFunctions('DialogWithAsserterror')]
    procedure Asserterror_InAModalHandler_RollsBackToTheLastCommit()
    var
        ALTUniversal: Record "ALT Universal";
        Result: Action;
    begin
        Cleanup.Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
        Commit();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 2;
        ALTUniversal.Insert();

        Result := Page.RunModal(Page::"Probe AH Dialog");

        Assert.AreEqual(1, Cnt(1), 'the committed row stays');
        Assert.AreEqual(0, Cnt(2), 'the write pending before the page opened is lost');
        Assert.AreEqual(0, Cnt(3), 'the handler''s write before its asserterror is lost too');
        Assert.AreEqual(0, Cnt(4), 'and the one inside it');
        Assert.IsFalse(Database.IsInWriteTransaction(), 'no write transaction is left');
    end;

    [ModalPageHandler]
    procedure DialogWithAsserterror(var Dialog: TestPage "Probe AH Dialog")
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 3;
        ALTUniversal.Insert();
        asserterror begin
            ALTUniversal.Init();
            ALTUniversal."Entry No." := 4;
            ALTUniversal.Insert();
            Error('in handler');
        end;
    end;
}
