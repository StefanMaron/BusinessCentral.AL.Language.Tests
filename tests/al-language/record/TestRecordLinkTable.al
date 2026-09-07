// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-addlink-method
// Scope: in-scope
// Fixtures used: ALT Link Host (60776)
//
// The claim under test is that the AL link surface (Rec.AddLink / HasLinks / DeleteLink /
// DeleteLinks / CopyLinks) and the Record Link table (2000000068) are TWO VIEWS OF ONE
// STORE, not two stores. Every test below crosses between the two surfaces in one
// direction or the other, or asserts that a link survives being read through a second
// record variable — which is the same claim, since a store keyed by anything narrower
// than the record's identity cannot answer it.
//
// codeunit "Record Link Management" is included because the System Application's own
// implementation of it (codeunit "Record Link Impl.") reaches the platform through a
// RecordRef built from a Variant, not through the caller's record instance.

codeunit 60777 "Test Record Link Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
    begin
        if Host.FindSet() then
            repeat
                RecordLink.Reset();
                RecordLink.SetRange("Record ID", Host.RecordId());
                RecordLink.DeleteAll(false);
            until Host.Next() = 0;
        Host.DeleteAll(false);
    end;

    local procedure Seed(EntryNo: Integer; var Host: Record "ALT Link Host")
    begin
        Host.Init();
        Host."Entry No." := EntryNo;
        Host.Name := 'HOST' + Format(EntryNo);
        Host.Insert();
    end;

    /// Write a Record Link row the way application code does: no "Link ID", which is an
    /// AutoIncrement primary key the platform fills in.
    local procedure InsertLinkRow(RecId: RecordId; Url: Text[2048]; Descr: Text[250])
    var
        RecordLink: Record "Record Link";
    begin
        RecordLink.Init();
        RecordLink."Record ID" := RecId;
        RecordLink.URL1 := Url;
        RecordLink.Description := Descr;
        RecordLink.Type := RecordLink.Type::Link;
        RecordLink.Company := CompanyName();
        RecordLink.Insert(true);
    end;

    local procedure LinkRowCount(RecId: RecordId): Integer
    var
        RecordLink: Record "Record Link";
    begin
        RecordLink.Reset();
        RecordLink.SetRange("Record ID", RecId);
        exit(RecordLink.Count());
    end;

    // ── The table is visible to the AL surface ───────────────────────────────────────

    [Test]
    procedure RecordLink_RowInsertedIntoTheTable_IsVisibleToHasLinks()
    var
        Host: Record "ALT Link Host";
    begin
        Initialize();
        Seed(1, Host);

        InsertLinkRow(Host.RecordId(), 'https://example.com/1', 'DIRECT');

        Assert.IsTrue(Host.HasLinks(),
            'HasLinks() must be true for a record whose Record Link row was written to the table directly');
    end;

    [Test]
    procedure RecordLink_RowInsertedIntoTheTable_IsRemovedByDeleteLinks()
    var
        Host: Record "ALT Link Host";
    begin
        Initialize();
        Seed(2, Host);
        InsertLinkRow(Host.RecordId(), 'https://example.com/2', 'DIRECT');

        Host.DeleteLinks();

        Assert.AreEqual(0, LinkRowCount(Host.RecordId()),
            'DeleteLinks() must remove the Record Link table rows, not just an internal flag');
        Assert.IsFalse(Host.HasLinks(), 'HasLinks() must be false after DeleteLinks()');
    end;

    // ── The AL surface is visible in the table ───────────────────────────────────────

    [Test]
    procedure RecordLink_AddLink_WritesARowIntoTheRecordLinkTable()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
        LinkId: Integer;
    begin
        Initialize();
        Seed(3, Host);

        LinkId := Host.AddLink('https://example.com/3', 'ADDED');

        Assert.AreEqual(1, LinkRowCount(Host.RecordId()),
            'AddLink() must leave exactly one Record Link row for the record');

        RecordLink.Reset();
        RecordLink.SetRange("Record ID", Host.RecordId());
        RecordLink.FindFirst();
        Assert.AreEqual(LinkId, RecordLink."Link ID",
            'AddLink() must return the Link ID of the Record Link row it created');
        Assert.AreEqual('https://example.com/3', RecordLink.URL1, 'URL1 must be the URL passed to AddLink()');
        Assert.AreEqual('ADDED', RecordLink.Description, 'Description must be the one passed to AddLink()');
        Assert.AreEqual('Link', Format(RecordLink.Type), 'AddLink() must create a row of type Link');
    end;

    [Test]
    procedure RecordLink_AddLink_IsVisibleToASecondRecordVariable()
    var
        Host: Record "ALT Link Host";
        Other: Record "ALT Link Host";
    begin
        Initialize();
        Seed(4, Host);
        Host.AddLink('https://example.com/4', 'ADDED');

        Other.Get(4);

        Assert.IsTrue(Other.HasLinks(),
            'A link belongs to the ROW, so a second record variable reading the same row must see it');
    end;

    [Test]
    procedure RecordLink_DeleteLink_RemovesOnlyTheAddressedRow()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
        FirstLinkId: Integer;
    begin
        Initialize();
        Seed(5, Host);
        FirstLinkId := Host.AddLink('https://example.com/5a', 'KEEP_ME_NOT');
        Host.AddLink('https://example.com/5b', 'KEEP_ME');

        Host.DeleteLink(FirstLinkId);

        Assert.AreEqual(1, LinkRowCount(Host.RecordId()),
            'DeleteLink(ID) must remove exactly one Record Link row');
        RecordLink.Reset();
        RecordLink.SetRange("Record ID", Host.RecordId());
        RecordLink.FindFirst();
        Assert.AreEqual('KEEP_ME', RecordLink.Description,
            'DeleteLink(ID) must remove the addressed row, not an arbitrary one');
        Assert.IsTrue(Host.HasLinks(), 'HasLinks() must still be true while one link remains');
    end;

    // ── Record Link Management crosses both surfaces ─────────────────────────────────

    [Test]
    procedure RecordLinkManagement_CopyLinks_CopiesTheSourceRowsAndLeavesOthersAlone()
    var
        Source: Record "ALT Link Host";
        Target: Record "ALT Link Host";
        Bystander: Record "ALT Link Host";
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        Initialize();
        Seed(6, Source);
        Seed(7, Target);
        Seed(8, Bystander);

        InsertLinkRow(Source.RecordId(), 'https://example.com/6a', 'LINK_ALPHA');
        InsertLinkRow(Source.RecordId(), 'https://example.com/6b', 'LINK_BRAVO');
        InsertLinkRow(Bystander.RecordId(), 'https://example.com/8', 'BYSTANDER');

        RecordLinkManagement.CopyLinks(Source, Target);

        Assert.AreEqual(2, LinkRowCount(Target.RecordId()),
            'CopyLinks must copy every Record Link row of the source onto the target');

        RecordLink.Reset();
        RecordLink.SetRange("Record ID", Target.RecordId());
        RecordLink.FindSet();
        Assert.AreEqual('LINK_ALPHA', RecordLink.Description, 'The first copied row must be the source''s first');
        Assert.AreEqual('https://example.com/6a', RecordLink.URL1, 'The first copied row must carry the source''s URL');
        RecordLink.Next();
        Assert.AreEqual('LINK_BRAVO', RecordLink.Description, 'The second copied row must be the source''s second');
        Assert.AreEqual('https://example.com/6b', RecordLink.URL1, 'The second copied row must carry the source''s URL');

        Assert.AreEqual(2, LinkRowCount(Source.RecordId()),
            'CopyLinks must leave the source''s own rows in place');
        Assert.AreEqual(1, LinkRowCount(Bystander.RecordId()),
            'CopyLinks must not touch the links of a record it was not given');
    end;

    [Test]
    procedure RecordLinkManagement_CopyLinks_IsVisibleToHasLinksOnTheTarget()
    var
        Source: Record "ALT Link Host";
        Target: Record "ALT Link Host";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        Initialize();
        Seed(9, Source);
        Seed(10, Target);
        Source.AddLink('https://example.com/9', 'ADDED');

        RecordLinkManagement.CopyLinks(Source, Target);

        Assert.IsTrue(Target.HasLinks(),
            'HasLinks() on the target must be true after Record Link Management.CopyLinks');
        Assert.AreEqual(1, LinkRowCount(Target.RecordId()),
            'CopyLinks must leave one Record Link row on the target');
    end;

    // ── Negative: the table enforces its own primary key ─────────────────────────────

    [Test]
    procedure RecordLink_InsertingADuplicateLinkId_Errors()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
        LinkId: Integer;
    begin
        Initialize();
        Seed(11, Host);
        LinkId := Host.AddLink('https://example.com/11', 'ADDED');

        RecordLink.Init();
        RecordLink."Link ID" := LinkId;
        RecordLink."Record ID" := Host.RecordId();
        RecordLink.URL1 := 'https://example.com/11-dup';
        RecordLink.Type := RecordLink.Type::Link;
        RecordLink.Company := CompanyName();
        asserterror RecordLink.Insert(false);

        Assert.ExpectedError('already exists');
    end;

    // ── The table and the AL surface share one Link ID sequence ──────────────────────

    [Test]
    procedure RecordLink_AddLink_AndUnnumberedTableInserts_ShareOneLinkIdSequence()
    var
        Host: Record "ALT Link Host";
        RecordLink: Record "Record Link";
        FirstInsertedId: Integer;
        AddedId: Integer;
        SecondInsertedId: Integer;
    begin
        Initialize();
        Seed(12, Host);

        // Order matters, and it is the whole point. The AL Insert goes FIRST and sets no
        // "Link ID", so the platform's AutoIncrement assigns one and the sequence is now
        // standing at that value. AddLink then has to continue that same sequence rather than
        // start one of its own — and the second Insert has to continue past AddLink's row.
        // Any writer numbering independently collides with one of the other two.
        RecordLink.Init();
        RecordLink."Record ID" := Host.RecordId();
        RecordLink.URL1 := 'https://example.com/12a';
        RecordLink.Description := 'INSERTED_FIRST';
        RecordLink.Type := RecordLink.Type::Link;
        RecordLink.Company := CompanyName();
        RecordLink.Insert(true);
        FirstInsertedId := RecordLink."Link ID";

        AddedId := Host.AddLink('https://example.com/12b', 'ADDED');

        Clear(RecordLink);
        RecordLink.Init();
        RecordLink."Record ID" := Host.RecordId();
        RecordLink.URL1 := 'https://example.com/12c';
        RecordLink.Description := 'INSERTED_SECOND';
        RecordLink.Type := RecordLink.Type::Link;
        RecordLink.Company := CompanyName();
        RecordLink.Insert(true);
        SecondInsertedId := RecordLink."Link ID";

        Assert.AreEqual(3, LinkRowCount(Host.RecordId()),
            'all three writes must survive — a reused Link ID would displace or reject one');
        Assert.IsTrue(FirstInsertedId > 0, 'an AutoIncrement Insert must assign a positive Link ID');
        Assert.IsTrue(AddedId > 0, 'AddLink must return a positive Link ID');
        Assert.IsTrue(SecondInsertedId > 0, 'the second Insert must assign a positive Link ID');
        Assert.AreNotEqual(FirstInsertedId, AddedId,
            'AddLink must continue the table''s Link ID sequence, not restart one of its own');
        Assert.AreNotEqual(AddedId, SecondInsertedId,
            'an Insert after AddLink must continue past AddLink''s row');
        Assert.AreNotEqual(FirstInsertedId, SecondInsertedId,
            'the two Inserts must not be handed the same Link ID either');
    end;

    // ── An uncommitted link is rolled back like any other uncommitted row ────────────

    [Test]
    procedure RecordLink_AddLink_InsideATrappedError_IsRolledBackLikeATableInsert()
    var
        Host: Record "ALT Link Host";
        Bystander: Record "ALT Link Host";
    begin
        Initialize();
        Seed(13, Host);
        Seed(14, Bystander);
        // The commit point matters, and it is why this is not just "asserterror undoes things".
        // Initialize() writes to the Record Link table itself, so without this Commit the
        // table's pre-error image is already taken before the link surface is ever used, and
        // the assertions below would hold whether or not the link surface participates in the
        // transaction at all. After the Commit, the FIRST write to the Record Link table is
        // AddLink's own.
        Commit();

        // Two writers of the same table inside one failing statement: the AL link surface and
        // a direct table Insert. Both are uncommitted, so a trapped error must undo both — a
        // link that survived while the row beside it vanished would be one table with two
        // different transaction invariants.
        asserterror
        begin
            Host.AddLink('https://example.com/13', 'ADDED');
            InsertLinkRow(Bystander.RecordId(), 'https://example.com/14', 'INSERTED');
            Error('ALT rollback probe');
        end;
        Assert.ExpectedError('ALT rollback probe');

        Assert.AreEqual(0, LinkRowCount(Host.RecordId()),
            'a link added inside a trapped error must be rolled back');
        Assert.AreEqual(0, LinkRowCount(Bystander.RecordId()),
            'a Record Link row inserted inside the same trapped error must be rolled back too');
        Assert.IsFalse(Host.HasLinks(), 'HasLinks() must be false after the rollback');
    end;

    // ── Copying a record onto itself ────────────────────────────────────────────────

    [Test]
    procedure RecordLinkManagement_CopyLinks_SourceOntoItself_DoesNotDuplicateTheRows()
    var
        Host: Record "ALT Link Host";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        Initialize();
        Seed(15, Host);
        InsertLinkRow(Host.RecordId(), 'https://example.com/15a', 'LINK_ALPHA');
        InsertLinkRow(Host.RecordId(), 'https://example.com/15b', 'LINK_BRAVO');

        RecordLinkManagement.CopyLinks(Host, Host);

        Assert.AreEqual(2, LinkRowCount(Host.RecordId()),
            'copying a record''s links onto itself must not duplicate them');
    end;
}
