// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-changecompany-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-open-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: shared Assert (60021); self-contained table 68390, codeunits 68391 (company arm), 68392
//                (rename and delete arm), 68393 (missing company)
// Probe: written against a real BC 27.5 service tier on Linux whose SQL Server has Full-Text Search (the
// :2022-fts image; without it creating a company fails); every literal below is what that tier produced.
// Other BC versions were not measured.
//
// Each arm that creates a company is a codeunit of its own (creating a company takes about a minute on
// the Linux tier; see TestRecordChangeCompanyRows.al). Pins:
//  - ChangeCompany keeps the filters, the current key and the marks of a record (a mark is a primary key, so a
//    mark of a row the other company lacks matches nothing), and works on a temporary record, which keeps
//    its rows;
//  - Copy and SetTable from a record or RecordRef of another company do not move the target to that company;
//    a RecordRef.GetTable does;
//  - Delete(false) of a company that holds rows removes the Company row (ChangeCompany answers false) and a company inserted again under
//    the name starts empty (codeunit 68394);
//  - a company that is renamed takes its data with it and the old name answers false; a company that is
//    deleted (with triggers) takes its data with it, and a new company of the same name starts empty;
//  - ChangeCompany to a company that does not exist: false when the result is used (the record stays
//    where it was), "The company "<name>" does not exist." / DB:RecordNotFound when it is not; the empty
//    name is the session company; the name is case sensitive; RecordRef.Open raises the same error;
//    a temporary record also answers false.
// BC versions: 27.5

table 68390 "Probe Chg Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(KT; Txt) { }
    }
}

codeunit 68391 "Probe Chg Company Arm"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CompanyTok: Label 'PRB CHGCO ARM', Locked = true;

    local procedure InsertCompany()
    var
        Company: Record Company;
    begin
        if Company.Get(CompanyTok) then
            Company.Delete(true);
        Company.Init();
        Company.Name := CompanyTok;
        Company.Insert();
        Commit();
    end;

    local procedure DeleteCompany()
    var
        Company: Record Company;
        Home: Record "Probe Chg Table";
    begin
        Home.DeleteAll();
        if Company.Get(CompanyTok) then
            Company.Delete(true);
        Commit();
    end;

    [Test]
    procedure ChangeCompany_KeepsFiltersKeyAndMarks_AndCopyDoesNotMoveTheTarget()
    var
        Home: Record "Probe Chg Table";
        Other: Record "Probe Chg Table";
        Moved: Record "Probe Chg Table";
        Target: Record "Probe Chg Table";
        Tmp: Record "Probe Chg Table" temporary;
        OtherRef: RecordRef;
        Ok: Boolean;
    begin
        InsertCompany();
        Home.DeleteAll();
        Home.Id := 1;
        Home.Txt := 'main1';
        Home.Insert();
        Home.Id := 2;
        Home.Txt := 'main2';
        Home.Insert();
        Home.Id := 3;
        Home.Txt := 'main3';
        Home.Insert();
        Other.ChangeCompany(CompanyTok);
        Other.DeleteAll();
        Other.Id := 10;
        Other.Txt := 'other10';
        Other.Insert();
        Other.Id := 2;
        Other.Txt := 'other2';
        Other.Insert();
        Commit();

        Moved.SetFilter(Id, '>=2');
        Moved.SetCurrentKey(Txt);
        Moved.FindSet();
        repeat
            Moved.Mark(true);
        until Moved.Next() = 0;
        Assert.AreEqual(2, Moved.Count(), 'two rows match in the session company');
        Ok := Moved.ChangeCompany(CompanyTok);
        Assert.IsTrue(Ok, 'ChangeCompany');
        Assert.AreEqual(CompanyTok, Moved.CurrentCompany(), 'company');
        Assert.AreEqual('Id: >=2', Moved.GetFilters(), 'the filter stays');
        Assert.AreEqual('Txt', Moved.CurrentKey(), 'the key stays');
        Assert.AreEqual(2, Moved.Count(), 'the filter applies in the other company (ids 2 and 10)');
        Moved.MarkedOnly(true);
        Assert.AreEqual(1, Moved.Count(), 'the marks stay, by primary key: id 2 exists in the other company, id 3 does not');

        Target.Copy(Other);
        Assert.AreNotEqual(CompanyTok, Target.CurrentCompany(), 'Copy does not move the target');
        Assert.AreEqual(CompanyName(), Target.CurrentCompany(), 'it stays in the session company');
        OtherRef.GetTable(Other);
        Assert.AreEqual(CompanyTok, OtherRef.CurrentCompany(), 'GetTable takes the company');
        Assert.AreEqual(2, OtherRef.Count(), 'and its rows');
        OtherRef.SetTable(Target);
        Assert.AreEqual(CompanyName(), Target.CurrentCompany(), 'SetTable does not move the target');
        Assert.AreEqual(3, Target.Count(), 'it reads the session company');

        Tmp.Id := 1;
        Tmp.Insert();
        Assert.IsTrue(Tmp.ChangeCompany(CompanyTok), 'a temporary record');
        Assert.AreEqual(CompanyTok, Tmp.CurrentCompany(), 'temporary record company');
        Assert.AreEqual(1, Tmp.Count(), 'it keeps its rows');

        DeleteCompany();
    end;
}

codeunit 68392 "Probe Chg Company Rename"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure CleanName(Name: Text[30])
    var
        Company: Record Company;
    begin
        if Company.Get(Name) then
            Company.Delete(true);
        Commit();
    end;

    local procedure NewCompany(Name: Text[30])
    var
        Company: Record Company;
    begin
        CleanName(Name);
        Company.Init();
        Company.Name := Name;
        Company.Insert();
        Commit();
    end;

    [Test]
    procedure Rename_TakesTheData_AndDeleteDropsIt()
    var
        Company: Record Company;
        Data: Record "Probe Chg Table";
        Later: Record "Probe Chg Table";
    begin
        CleanName('PRB CHGCO REN2');
        NewCompany('PRB CHGCO REN1');
        Data.ChangeCompany('PRB CHGCO REN1');
        Data.Id := 1;
        Data.Txt := 'x';
        Data.Insert();
        Commit();

        Company.Get('PRB CHGCO REN1');
        Company.Rename('PRB CHGCO REN2');
        Commit();

        Assert.IsFalse(Later.ChangeCompany('PRB CHGCO REN1'), 'the old name');
        Assert.IsTrue(Later.ChangeCompany('PRB CHGCO REN2'), 'the new name');
        Assert.AreEqual(1, Later.Count(), 'the data went with the company');

        Company.Get('PRB CHGCO REN2');
        Company.Delete(true);
        Commit();
        Assert.IsFalse(Later.ChangeCompany('PRB CHGCO REN2'), 'a deleted company');

        NewCompany('PRB CHGCO REN2');
        Assert.IsTrue(Later.ChangeCompany('PRB CHGCO REN2'), 'a new company of the same name');
        Assert.AreEqual(0, Later.Count(), 'starts empty');

        CleanName('PRB CHGCO REN2');
    end;
}

codeunit 68393 "Probe Chg Company Missing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ChangeCompany_ToAMissingCompany_FalseOrAnError()
    var
        Rec: Record "Probe Chg Table";
        Tmp: Record "Probe Chg Table" temporary;
        Ok: Boolean;
    begin
        Ok := Rec.ChangeCompany('NoSuchCompany');
        Assert.IsFalse(Ok, 'result used');
        Assert.AreEqual(CompanyName(), Rec.CurrentCompany(), 'the record stays in the session company');

        asserterror Rec.ChangeCompany('NoSuchCompany');
        Assert.AreEqual('The company "NoSuchCompany" does not exist.', GetLastErrorText(), 'text');
        Assert.AreEqual('DB:RecordNotFound', GetLastErrorCode(), 'code');

        Ok := Tmp.ChangeCompany('NoSuchCompany');
        Assert.IsFalse(Ok, 'temporary record');
    end;

    [Test]
    procedure ChangeCompany_EmptyNameIsTheSessionCompany_AndTheNameIsCaseSensitive()
    var
        Rec: Record "Probe Chg Table";
        Ok: Boolean;
    begin
        Ok := Rec.ChangeCompany('');
        Assert.IsTrue(Ok, 'empty name');
        Assert.AreEqual(CompanyName(), Rec.CurrentCompany(), 'empty name company');

        Ok := Rec.ChangeCompany(LowerCase(CompanyName()));
        Assert.IsFalse(Ok, 'lower case name');
        Assert.AreEqual(CompanyName(), Rec.CurrentCompany(), 'the record stays');
    end;

    [Test]
    procedure RecordRefOpen_OnAMissingCompany_RaisesTheSameError()
    var
        Ref: RecordRef;
    begin
        asserterror Ref.Open(Database::"Probe Chg Table", false, 'NoSuchCompany');

        Assert.AreEqual('The company "NoSuchCompany" does not exist.', GetLastErrorText(), 'text');
        Assert.AreEqual('DB:RecordNotFound', GetLastErrorCode(), 'code');
    end;
}

codeunit 68394 "Probe Chg Company Delete False"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DeleteWithoutTriggers_OfACompanyWithRows_RemovesTheCompany_AndANewOneStartsEmpty()
    // CLAIM: Delete(false) of a company that holds rows removes the Company row; ChangeCompany to it answers false; a company inserted again
    // under the same name starts empty.
    var
        Company: Record Company;
        Data: Record "Probe Chg Table";
        Later: Record "Probe Chg Table";
    begin
        if Company.Get('PRB CHGCO DEL') then
            Company.Delete(true);
        Company.Init();
        Company.Name := 'PRB CHGCO DEL';
        Company.Insert();
        Commit();
        Data.ChangeCompany('PRB CHGCO DEL');
        Data.Id := 1;
        Data.Insert();
        Commit();

        Company.Get('PRB CHGCO DEL');
        Company.Delete(false);
        Commit();

        Assert.IsFalse(Company.Get('PRB CHGCO DEL'), 'the Company row is gone');
        Assert.IsFalse(Later.ChangeCompany('PRB CHGCO DEL'), 'ChangeCompany');

        Company.Init();
        Company.Name := 'PRB CHGCO DEL';
        Company.Insert();
        Commit();
        Assert.IsTrue(Later.ChangeCompany('PRB CHGCO DEL'), 'inserted again');
        Assert.AreEqual(0, Later.Count(), 'starts empty');

        Company.Get('PRB CHGCO DEL');
        Company.Delete(true);
        Commit();
    end;
}
