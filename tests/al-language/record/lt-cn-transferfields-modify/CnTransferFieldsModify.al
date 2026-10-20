// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 84884-84885, test codeunit 84886
// Probe: corpus issue #669 (writer CN), item 51 (microsoft/AL#3875): Rec1.Insert(), then Rec1.TransferFields(Rec2) with the same primary key,
// then Rec1.Modify(). Does Modify raise "Sorry, we have just updated this page" because TransferFields or Copy carry the source row's version?
// Sources: Rec2 built in memory, Rec2 read from the database, Rec2 read and then modified by another variable (Rec1 is then stale), a row of
// another table, TransferFields(Rec2, false), and Record.Copy. The stale Modify without TransferFields is the control.
// Measured (local BC 29, checked by the CI matrix): every case starts from a committed row. In-memory and freshly read sources modify fine. A stale Modify (Commit after the other write) fails with
//   DB:RecordChanged; TransferFields(Newer) with the primary key (the default) and Copy(Newer) make the buffer current, so Modify succeeds;
//   TransferFields(Newer, false) does not, and Modify fails with DB:RecordChanged. A row of another table with the same key transfers and modifies.
// BC versions: 27, 28, 29

table 84884 "LT CN TF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 84885 "LT CN TF Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 84886 "LT CN TF Modify"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Prep(var R1: Record "LT CN TF Row")
    var
        Other: Record "LT CN TF Other";
    begin
        R1.DeleteAll();
        Other.DeleteAll();
        R1.Init();
        R1.Id := 1;
        R1.Name := 'first';
        R1.Qty := 1;
        R1.Insert();
        Commit();
    end;

    local procedure NameInDb(): Text
    var
        R: Record "LT CN TF Row";
    begin
        R.Get(1);
        exit(R.Name + '/' + Format(R.Qty));
    end;

    [Test]
    procedure TF_InMemorySource_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Init();
        R2.Id := 1;
        R2.Name := 'mem';
        R2.Qty := 2;
        R1.TransferFields(R2);
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'mem/2');
        Observer.Verify();
    end;

    [Test]
    procedure TF_SourceReadFromDb_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Get(1);
        R1.TransferFields(R2);
        R1.Name := 'changed';
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'changed/1');
        Observer.Verify();
    end;

    [Test]
    procedure Control_StaleModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Get(1);
        R2.Name := 'second';
        R2.Modify();
        Commit();
        R1.Name := 'stale';
        asserterror R1.Modify();
        Observer.ObserveError('modify');
        Observer.Observe('db', NameInDb());
        Observer.Expect('modify|text', 'The changes to the LT CN TF Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('modify|code', 'DB:RecordChanged');
        Observer.Expect('db', 'second/1');
        Observer.Verify();
    end;

    [Test]
    procedure TF_FromNewerCopy_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Get(1);
        R2.Name := 'second';
        R2.Modify();
        Commit();
        R1.TransferFields(R2);
        R1.Qty := 9;
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'second/9');
        Observer.Verify();
    end;

    [Test]
    procedure TF_NoKey_FromNewerCopy_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Get(1);
        R2.Name := 'second';
        R2.Modify();
        Commit();
        R1.TransferFields(R2, false);
        R1.Qty := 9;
        asserterror R1.Modify();
        Observer.ObserveError('modify');
        Observer.Observe('db', NameInDb());
        Observer.Expect('modify|text', 'The changes to the LT CN TF Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('modify|code', 'DB:RecordChanged');
        Observer.Expect('db', 'second/1');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_FromNewerCopy_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Get(1);
        R2.Name := 'second';
        R2.Modify();
        Commit();
        R1.Copy(R2);
        R1.Qty := 9;
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'second/9');
        Observer.Verify();
    end;

    [Test]
    procedure TF_OtherTable_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
    begin
        Prep(R1);
        O.Init();
        O.Id := 1;
        O.Name := 'other';
        O.Qty := 3;
        O.Insert();
        Commit();
        O.Get(1);
        R1.TransferFields(O);
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'other/3');
        Observer.Verify();
    end;
}
