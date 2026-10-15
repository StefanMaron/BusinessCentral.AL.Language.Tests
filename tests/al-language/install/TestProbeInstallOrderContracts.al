// Observe-only probes (writer A). Rows: Install order of OnInstallAppPerCompany / OnInstallAppPerDatabase, company in
// per-database code, per-company table access from per-database code. NOTE: the install codeunit only runs when the
// probe app is installed; the test reads what it wrote. Dialog no-op probes are here too.
table 69810 "PA Install Log"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Seq; Integer) { AutoIncrement = true; }
        field(2; Entry; Text[250]) { }
    }
    keys { key(PK; Seq) { Clustered = true; } }
}

table 69811 "PA Install Company Table"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 69818 "PA Install A"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        Log('A OnInstallAppPerDatabase company=[' + CompanyName() + ']');
        Log('A per-database access to per-company table: ' + TryAccess());
        Log('A per-database access via ChangeCompany: ' + TryAccessChanged());
    end;

    trigger OnInstallAppPerCompany()
    begin
        Log('A OnInstallAppPerCompany company=[' + CompanyName() + ']');
    end;

    local procedure Log(T: Text)
    var
        L: Record "PA Install Log";
    begin
        L.Entry := CopyStr(T, 1, MaxStrLen(L.Entry));
        L.Insert();
    end;

    local procedure TryAccess(): Text
    begin
        if TryAccessF() then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryAccessF()
    var
        T: Record "PA Install Company Table";
        C: Integer;
    begin
        C := T.Count();
    end;

    local procedure TryAccessChanged(): Text
    begin
        if TryAccessChangedF() then
            exit('ok');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryAccessChangedF()
    var
        T: Record "PA Install Company Table";
        Co: Record Company;
        C: Integer;
    begin
        if Co.FindFirst() then
            T.ChangeCompany(Co.Name);
        C := T.Count();
    end;
}

codeunit 69819 "PA Install B"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        L: Record "PA Install Log";
    begin
        L.Entry := CopyStr('B OnInstallAppPerCompany company=[' + CompanyName() + ']', 1, 250);
        L.Insert();
    end;

    trigger OnInstallAppPerDatabase()
    var
        L: Record "PA Install Log";
    begin
        L.Entry := CopyStr('B OnInstallAppPerDatabase company=[' + CompanyName() + ']', 1, 250);
        L.Insert();
    end;
}

codeunit 69820 "PA Install Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Install_RecordedOrder()
    var
        O: Codeunit "Probe Observer";
        L: Record "PA Install Log";
    begin
        O.Observe('row_count', Format(L.Count()));
        if L.FindSet() then
            repeat
                O.Observe('seq_' + Format(L.Seq, 3, '<Integer,3><Filler Character 0>'), L.Entry);
            until L.Next() = 0;
        O.Expect('row_count', '0');
        O.Verify();
    end;

    [Test]
    procedure Dialog_OpenUpdateClose()
    var
        O: Codeunit "Probe Observer";
        D: Dialog;
    begin
        D.Open('Working #1######');
        D.Update(1, 'x');
        D.Update();
        D.Close();
        O.Observe('dialog_open_update_close', 'no error');
        O.Expect('dialog_open_update_close', 'no error');
        O.Verify();
    end;
}
