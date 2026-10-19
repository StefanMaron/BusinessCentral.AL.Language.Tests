// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-addlink-method
// Scope: in-scope
// Fixtures used: ALT Link Host (60776), ALT Link Host No Company (67680)
//
// What the platform writes into the Record Link (2000000068) columns that the caller does not
// pass: "User ID", Created and Company on Rec.AddLink, and which columns a CopyLinks copy keeps.
// And how the link readers (HasLinks, DeleteLinks, DeleteLink, CopyLinks, Rename) filter on the
// Company column.
// Codeunit 60777 "Test Record Link Table" covers the rows' existence, URL1/Description/Type and
// the Link ID; this one covers the provenance columns it leaves out.

codeunit 67681 "Test Record Link Columns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Host: Record "ALT Link Host";
        NoCompanyHost: Record "ALT Link Host No Company";
        RecordLink: Record "Record Link";
    begin
        if Host.FindSet() then
            repeat
                RecordLink.Reset();
                RecordLink.SetRange("Record ID", Host.RecordId());
                RecordLink.DeleteAll(false);
            until Host.Next() = 0;
        Host.DeleteAll(false);
        if NoCompanyHost.FindSet() then
            repeat
                RecordLink.Reset();
                RecordLink.SetRange("Record ID", NoCompanyHost.RecordId());
                RecordLink.DeleteAll(false);
            until NoCompanyHost.Next() = 0;
        NoCompanyHost.DeleteAll(false);
    end;

    local procedure Seed(EntryNo: Integer; var Host: Record "ALT Link Host")
    begin
        Host.Init();
        Host."Entry No." := EntryNo;
        Host.Name := 'COLS' + Format(EntryNo);
        Host.Insert();
    end;

    local procedure SeedNoCompany(EntryNo: Integer; var Host: Record "ALT Link Host No Company")
    begin
        Host.Init();
        Host."Entry No." := EntryNo;
        Host.Insert();
    end;

    local procedure OnlyLinkOf(RecId: RecordId; var RecordLink: Record "Record Link")
    begin
        RecordLink.Reset();
        RecordLink.SetRange("Record ID", RecId);
        Assert.AreEqual(1, RecordLink.Count(), 'expected exactly one Record Link row for the record');
        RecordLink.FindFirst();
    end;

    /// The user name as the platform stores it in "User ID": UserId() without any DOMAIN\ prefix.
    local procedure CurrentUserWithoutDomain(): Text
    var
        CurrentUser: Text;
    begin
        CurrentUser := UserId();
        exit(CopyStr(CurrentUser, StrPos(CurrentUser, '\') + 1));
    end;

    // ── AddLink stamps the session's provenance ─────────────────────────────────────

    [Test]
    procedure RecordLinkColumns_AddLink_WritesTheCurrentUserIntoUserId()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
    begin
        Initialize();
        Seed(1, Host);

        Host.AddLink('https://example.com/cols/1', 'USER');

        OnlyLinkOf(Host.RecordId(), RecordLink);
        Assert.AreNotEqual('', RecordLink."User ID", 'AddLink() must write a User ID, not leave it blank');
        Assert.AreEqual(CurrentUserWithoutDomain(), RecordLink."User ID",
            'AddLink() must write the current user (UserId() without a domain) into User ID');
    end;

    [Test]
    procedure RecordLinkColumns_AddLink_StampsCreatedWithTheCurrentDateTime()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
        Before: DateTime;
        After: DateTime;
    begin
        Initialize();
        Seed(2, Host);

        Before := CurrentDateTime();
        Host.AddLink('https://example.com/cols/2', 'CREATED');
        After := CurrentDateTime();

        OnlyLinkOf(Host.RecordId(), RecordLink);
        Assert.AreNotEqual(0DT, RecordLink.Created, 'AddLink() must stamp Created');
        // One second either side: the stored value is rounded by the database.
        Assert.IsTrue(RecordLink.Created >= Before - 1000,
            StrSubstNo('Created %1 must not be before the AddLink() call started (%2)', RecordLink.Created, Before));
        Assert.IsTrue(RecordLink.Created <= After + 1000,
            StrSubstNo('Created %1 must not be after the AddLink() call returned (%2)', RecordLink.Created, After));
    end;

    [Test]
    procedure RecordLinkColumns_AddLink_OnAPerCompanyTable_WritesTheCompany()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
    begin
        Initialize();
        Seed(3, Host);

        Host.AddLink('https://example.com/cols/3', 'COMPANY');

        OnlyLinkOf(Host.RecordId(), RecordLink);
        Assert.AreEqual(CompanyName(), RecordLink.Company,
            'AddLink() on a per-company table must write the current company');
    end;

    [Test]
    procedure RecordLinkColumns_AddLink_OnATableNotPerCompany_LeavesCompanyEmpty()
    var
        Host: Record "ALT Link Host No Company";
        RecordLink: Record "Record Link";
    begin
        Initialize();
        SeedNoCompany(4, Host);

        Host.AddLink('https://example.com/cols/4', 'NO COMPANY');

        OnlyLinkOf(Host.RecordId(), RecordLink);
        Assert.AreEqual('', RecordLink.Company,
            'AddLink() on a table that is not per company must leave Company empty');
        Assert.IsTrue(Host.HasLinks(), 'HasLinks() must find the link of a table that is not per company');
    end;

    [Test]
    procedure RecordLinkColumns_AddLink_GivesEachRowItsOwnSystemId()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
        FirstId: Integer;
        SecondId: Integer;
        FirstSystemId: Guid;
    begin
        Initialize();
        Seed(11, Host);

        FirstId := Host.AddLink('https://example.com/cols/11a', 'FIRST');
        SecondId := Host.AddLink('https://example.com/cols/11b', 'SECOND');

        RecordLink.Get(FirstId);
        Assert.IsFalse(IsNullGuid(RecordLink.SystemId), 'AddLink() must give the row a SystemId');
        FirstSystemId := RecordLink.SystemId;
        RecordLink.Get(SecondId);
        Assert.IsFalse(IsNullGuid(RecordLink.SystemId), 'AddLink() must give the second row a SystemId');
        Assert.AreNotEqual(FirstSystemId, RecordLink.SystemId, 'two AddLink() rows must not share a SystemId');
        Assert.IsTrue(RecordLink.GetBySystemId(FirstSystemId), 'GetBySystemId must find a row AddLink() wrote');
        Assert.AreEqual(FirstId, RecordLink."Link ID", 'GetBySystemId must find the first AddLink() row');
    end;

    // ── CopyLinks copies the row, it does not re-create it ──────────────────────────

    [Test]
    procedure RecordLinkColumns_CopyLinks_KeepsTheSourceRowsProvenanceColumns()
    var
        Source: Record "ALT Link Host";
        Target: Record "ALT Link Host";
        SourceLink: Record "Record Link";
        CopiedLink: Record "Record Link";
        NoteOut: OutStream;
        NoteIn: InStream;
        NoteText: Text;
        Stamp: DateTime;
    begin
        Initialize();
        Seed(5, Source);
        Seed(6, Target);
        Stamp := CreateDateTime(20200102D, 030405T);

        SourceLink.Init();
        SourceLink."Record ID" := Source.RecordId();
        SourceLink.URL1 := 'https://example.com/cols/5';
        SourceLink.Description := 'PROVENANCE';
        SourceLink.Type := SourceLink.Type::Note;
        SourceLink."User ID" := 'LINKAUTHOR';
        SourceLink."To User ID" := 'LINKRECIPIENT';
        SourceLink.Notify := true;
        SourceLink.Created := Stamp;
        SourceLink.Company := CompanyName();
        SourceLink.Note.CreateOutStream(NoteOut);
        NoteOut.WriteText('the note body');
        SourceLink.Insert(true);

        Target.CopyLinks(Source);

        OnlyLinkOf(Target.RecordId(), CopiedLink);
        Assert.AreNotEqual(SourceLink."Link ID", CopiedLink."Link ID", 'the copy must be a new row');
        Assert.IsFalse(IsNullGuid(CopiedLink.SystemId), 'the copy must have a SystemId');
        Assert.AreNotEqual(SourceLink.SystemId, CopiedLink.SystemId, 'the copy must have its own SystemId');
        Assert.AreEqual('PROVENANCE', CopiedLink.Description, 'the copy must keep the Description');
        Assert.AreEqual('Note', Format(CopiedLink.Type), 'the copy must keep the Type');
        Assert.AreEqual('LINKAUTHOR', CopiedLink."User ID", 'the copy must keep the source row''s User ID');
        Assert.AreEqual('LINKRECIPIENT', CopiedLink."To User ID", 'the copy must keep the To User ID');
        Assert.IsTrue(CopiedLink.Notify, 'the copy must keep Notify');
        Assert.AreEqual(Stamp, CopiedLink.Created, 'the copy must keep the source row''s Created');
        CopiedLink.CalcFields(Note);
        CopiedLink.Note.CreateInStream(NoteIn);
        NoteIn.ReadText(NoteText);
        Assert.AreEqual('the note body', NoteText, 'the copy must keep the Note');
    end;

    [Test]
    procedure RecordLinkColumns_CopyLinks_OntoATableNotPerCompany_LeavesCompanyEmpty()
    var
        Source: Record "ALT Link Host";
        Target: Record "ALT Link Host No Company";
        CopiedLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        Initialize();
        Seed(7, Source);
        SeedNoCompany(8, Target);
        Source.AddLink('https://example.com/cols/7', 'TO NO COMPANY');

        RecordLinkManagement.CopyLinks(Source, Target);

        OnlyLinkOf(Target.RecordId(), CopiedLink);
        Assert.AreEqual('', CopiedLink.Company,
            'a copy onto a table that is not per company must have an empty Company');
    end;

    [Test]
    procedure RecordLinkColumns_CopyLinks_OntoAPerCompanyTable_WritesTheCompany()
    var
        Source: Record "ALT Link Host No Company";
        Target: Record "ALT Link Host";
        CopiedLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        Initialize();
        SeedNoCompany(9, Source);
        Seed(10, Target);
        Source.AddLink('https://example.com/cols/9', 'TO COMPANY');

        RecordLinkManagement.CopyLinks(Source, Target);

        OnlyLinkOf(Target.RecordId(), CopiedLink);
        Assert.AreEqual(CompanyName(), CopiedLink.Company,
            'a copy onto a per-company table must carry the current company');
    end;

    // ── The readers filter Company for a per-company table, and only then ────────────
    //
    // HasLinks, DeleteLinks, CopyLinks and a Rename's link move find a record's links by
    // "Record ID" and, when the record's table is per company, also by Company = the record's
    // company. A Record Link row naming another company, or no company, is not one of the
    // links of a per-company record. DeleteLink(ID) compares Company with the record's company
    // whatever the table.

    local procedure InsertLinkRowWithCompany(RecId: RecordId; Url: Text[2048]; LinkCompany: Text[30]): Integer
    var
        RecordLink: Record "Record Link";
    begin
        RecordLink.Init();
        RecordLink."Record ID" := RecId;
        RecordLink.URL1 := Url;
        RecordLink.Description := 'COMPANY FILTER';
        RecordLink.Company := LinkCompany;
        RecordLink.Insert(true);
        exit(RecordLink."Link ID");
    end;

    local procedure LinkRowCount(RecId: RecordId): Integer
    var
        RecordLink: Record "Record Link";
    begin
        RecordLink.SetRange("Record ID", RecId);
        exit(RecordLink.Count());
    end;

    local procedure OtherCompany(): Text[30]
    begin
        exit('ALT LINK OTHER COMPANY');
    end;

    [Test]
    procedure RecordLinkColumns_HasLinks_OnAPerCompanyTable_IgnoresARowOfAnotherCompany()
    var
        Host: Record "ALT Link Host";
    begin
        Initialize();
        Seed(12, Host);
        InsertLinkRowWithCompany(Host.RecordId(), 'https://example.com/cols/12', OtherCompany());

        Assert.AreEqual(1, LinkRowCount(Host.RecordId()), 'the row of another company must be in the table');
        Assert.IsFalse(Host.HasLinks(),
            'HasLinks() on a per-company table must not see a Record Link row of another company');

        InsertLinkRowWithCompany(Host.RecordId(), 'https://example.com/cols/12b', CompanyName());
        Assert.IsTrue(Host.HasLinks(), 'HasLinks() must see the row of the current company');
    end;

    [Test]
    procedure RecordLinkColumns_HasLinks_OnAPerCompanyTable_IgnoresARowWithNoCompany()
    var
        Host: Record "ALT Link Host";
    begin
        Initialize();
        Seed(13, Host);
        InsertLinkRowWithCompany(Host.RecordId(), 'https://example.com/cols/13', '');

        Assert.AreEqual(1, LinkRowCount(Host.RecordId()), 'the row with no company must be in the table');
        Assert.IsFalse(Host.HasLinks(),
            'HasLinks() on a per-company table must not see a Record Link row with an empty Company');
    end;

    [Test]
    procedure RecordLinkColumns_HasLinks_OnATableNotPerCompany_SeesARowOfAnyCompany()
    var
        Host: Record "ALT Link Host No Company";
    begin
        Initialize();
        SeedNoCompany(14, Host);
        InsertLinkRowWithCompany(Host.RecordId(), 'https://example.com/cols/14', OtherCompany());

        Assert.IsTrue(Host.HasLinks(),
            'HasLinks() on a table that is not per company must not filter on Company');
    end;

    [Test]
    procedure RecordLinkColumns_DeleteLinks_OnAPerCompanyTable_LeavesTheRowOfAnotherCompany()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
        OtherId: Integer;
    begin
        Initialize();
        Seed(15, Host);
        OtherId := InsertLinkRowWithCompany(Host.RecordId(), 'https://example.com/cols/15a', OtherCompany());
        Host.AddLink('https://example.com/cols/15b', 'OWN');
        Assert.AreEqual(2, LinkRowCount(Host.RecordId()), 'two Record Link rows before DeleteLinks()');

        Host.DeleteLinks();

        Assert.AreEqual(1, LinkRowCount(Host.RecordId()),
            'DeleteLinks() on a per-company table must delete only the current company''s rows');
        Assert.IsTrue(RecordLink.Get(OtherId), 'the row of another company must survive DeleteLinks()');
    end;

    [Test]
    procedure RecordLinkColumns_DeleteLinks_OnATableNotPerCompany_DeletesARowOfAnyCompany()
    var
        Host: Record "ALT Link Host No Company";
    begin
        Initialize();
        SeedNoCompany(16, Host);
        InsertLinkRowWithCompany(Host.RecordId(), 'https://example.com/cols/16', OtherCompany());

        Host.DeleteLinks();

        Assert.AreEqual(0, LinkRowCount(Host.RecordId()),
            'DeleteLinks() on a table that is not per company must not filter on Company');
    end;

    [Test]
    procedure RecordLinkColumns_DeleteLink_OnAPerCompanyTable_LeavesTheRowOfAnotherCompany()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
        OtherId: Integer;
    begin
        Initialize();
        Seed(17, Host);
        OtherId := InsertLinkRowWithCompany(Host.RecordId(), 'https://example.com/cols/17', OtherCompany());

        Host.DeleteLink(OtherId);

        Assert.IsTrue(RecordLink.Get(OtherId),
            'DeleteLink(ID) must not delete a row whose Company is not the record''s company');
    end;

    [Test]
    procedure RecordLinkColumns_DeleteLink_OnATableNotPerCompany_LeavesTheRowItsAddLinkWrote()
    var
        Host: Record "ALT Link Host No Company";
        RecordLink: Record "Record Link";
        LinkId: Integer;
    begin
        Initialize();
        SeedNoCompany(18, Host);
        LinkId := Host.AddLink('https://example.com/cols/18', 'NO COMPANY');

        Host.DeleteLink(LinkId);

        // AddLink wrote an empty Company, and DeleteLink(ID) compares it with the record's
        // company, which for an open record is the session's company whatever the table.
        Assert.IsTrue(RecordLink.Get(LinkId),
            'DeleteLink(ID) compares Company with the record''s company even when the table is not per company');
    end;

    [Test]
    procedure RecordLinkColumns_CopyLinks_FromAPerCompanyTable_CopiesOnlyTheCurrentCompanysRows()
    var
        Source: Record "ALT Link Host";
        Target: Record "ALT Link Host";
        CopiedLink: Record "Record Link";
    begin
        Initialize();
        Seed(19, Source);
        Seed(20, Target);
        InsertLinkRowWithCompany(Source.RecordId(), 'https://example.com/cols/19a', OtherCompany());
        Source.AddLink('https://example.com/cols/19b', 'OWN');

        Target.CopyLinks(Source);

        OnlyLinkOf(Target.RecordId(), CopiedLink);
        Assert.AreEqual('https://example.com/cols/19b', CopiedLink.URL1,
            'CopyLinks() from a per-company table must copy only the current company''s row');
    end;

    [Test]
    procedure RecordLinkColumns_Rename_OnAPerCompanyTable_MovesOnlyTheCurrentCompanysRows()
    var
        Host: Record "ALT Link Host";
        Renamed: Record "ALT Link Host";
        RecordLink: Record "Record Link";
        OldRecId: RecordId;
        OtherId: Integer;
    begin
        Initialize();
        Seed(21, Host);
        OldRecId := Host.RecordId();
        // Initialize finds link rows through existing hosts; a row left on this key by an earlier
        // run of this test has no host any more, so clear it by key.
        RecordLink.SetRange("Record ID", OldRecId);
        RecordLink.DeleteAll(false);
        RecordLink.Reset();
        OtherId := InsertLinkRowWithCompany(OldRecId, 'https://example.com/cols/21a', OtherCompany());
        Host.AddLink('https://example.com/cols/21b', 'OWN');

        Host.Rename(22);

        Renamed.Get(22);
        OnlyLinkOf(Renamed.RecordId(), RecordLink);
        Assert.AreEqual('https://example.com/cols/21b', RecordLink.URL1,
            'Rename() must move the current company''s link to the new key');
        RecordLink.Get(OtherId);
        Assert.AreEqual(Format(OldRecId), Format(RecordLink."Record ID"),
            'Rename() must leave the row of another company on the old key');
    end;
}
