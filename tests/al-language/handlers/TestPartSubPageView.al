// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: SPV Row (60979), SPV Host (60983), SPV Filtered Part (60986),
//                SPV Open Part (60987), Assert (60021)
//
/// <summary>
/// Pins that a part's SubPageView filters the rows the part shows.
///
/// SubPageView is the sibling of SubPageLink on the same part definition: the link ties the part
/// to the host's current row, the view is a standing filter and sort order declared on the part
/// itself. The corpus covers SubPageLink (TestPagePartLinkFilterGroup.al,
/// TestPageSubpagePartConstFilter.al) and mentions SubPageView nowhere.
///
/// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4188, which measures the
/// runner reading SubPageLink at 136 sites under AlRunner/ and SubPageView at ZERO -- so a part
/// declaring a view is expected to show rows the view excludes. Nothing here predicts the
/// runner's answer.
///
/// TWO PARTS ON THE ONE HOST, and the pair is the design. Both are bound to the same table and
/// the same rows; only one declares a SubPageView. So:
///   - the filtered part showing only matching rows, AND the open part showing all of them,
///     together say the view filtered rather than something else having emptied the part;
///   - the filtered part showing ALL rows says the view was ignored -- the #4188 shape;
///   - both parts showing nothing says the fixture never seeded, and neither arm above means
///     anything.
/// A single part could not separate the second case from the third.
///
/// BOTH ARMS WALK THE PART WITH First/Next AND ASSERT WHICH ENTRIES APPEAR, rather than
/// counting rows to a total. An editable ListPart shows a trailing blank new row, so a count
/// measures n+1 (BC answered 5 for four seeded rows, and the blank row's empty Bucket read as a
/// view violation). Asserting entry numbers is also stronger than a count: it says the filtered
/// part skips entry 2 specifically, and the control part reaches it.

table 60979 "SPV Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Bucket; Code[10]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 60953 "SPV Probe"
{
    SingleInstance = true;

    var
        G0: Text;
        G2: Text;
        G4: Text;
        Opened: Boolean;

    procedure Reset()
    begin
        G0 := '';
        G2 := '';
        G4 := '';
        Opened := false;
    end;

    procedure Record(NewG0: Text; NewG2: Text; NewG4: Text)
    begin
        G0 := NewG0;
        G2 := NewG2;
        G4 := NewG4;
        Opened := true;
    end;

    procedure WasOpened(): Boolean
    begin
        exit(Opened);
    end;

    procedure Groups(): Text
    begin
        exit('g0=' + G0 + '|g2=' + G2 + '|g4=' + G4);
    end;
}

page 60986 "SPV Filtered Part"
{
    PageType = ListPart;
    SourceTable = "SPV Row";
    ApplicationArea = All;
    Caption = 'SPV Filtered Part';
    // No SourceTableView here on purpose: the subject is SubPageView, declared on the part
    // CONTROL in the host's layout. SourceTableView is a different property on the page itself,
    // and the corpus already covers it (ALTSourceTableViewList, ALTSourceObjectFlagsPage) --
    // testing it here would pin the wrong thing and pass whatever the runner does with the view.

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Bucket; Rec.Bucket) { ApplicationArea = All; }
            }
        }
    }

    // Record which filter group the view's filter landed in. Reading here rather than
    // asserting keeps the page a fixture; the arm decides what the values mean.
    trigger OnOpenPage()
    var
        Probe: Codeunit "SPV Probe";
        F0: Text;
        F2: Text;
        F4: Text;
    begin
        Rec.FilterGroup(0);
        F0 := Rec.GetFilter(Bucket);
        Rec.FilterGroup(2);
        F2 := Rec.GetFilter(Bucket);
        Rec.FilterGroup(4);
        F4 := Rec.GetFilter(Bucket);
        Rec.FilterGroup(0);
        Probe.Record(F0, F2, F4);
    end;
}

page 60987 "SPV Open Part"
{
    PageType = ListPart;
    SourceTable = "SPV Row";
    ApplicationArea = All;
    Caption = 'SPV Open Part';
    // No view: the control. Same table, same rows.

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Bucket; Rec.Bucket) { ApplicationArea = All; }
            }
        }
    }
}

page 60983 "SPV Host"
{
    PageType = Card;
    SourceTable = "SPV Row";
    ApplicationArea = All;
    Caption = 'SPV Host';

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }

            // Neither part declares SubPageLink: this test is about the VIEW alone, and a link
            // would tie both parts to the host row and confound the two.
            part(FilteredPart; "SPV Filtered Part")
            {
                ApplicationArea = All;
                // THE SUBJECT.
                SubPageView = where(Bucket = const('KEEP'));
            }
            part(OpenPart; "SPV Open Part") { ApplicationArea = All; }
        }
    }
}

codeunit 60938 "SPV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "SPV Row";
        Probe: Codeunit "SPV Probe";
    begin
        Probe.Reset();
        Row.DeleteAll();
        AddRow(1, 'KEEP');
        AddRow(2, 'DROP');
        AddRow(3, 'KEEP');
        AddRow(4, 'DROP');
    end;

    local procedure AddRow(EntryNo: Integer; NewBucket: Code[10])
    var
        Row: Record "SPV Row";
    begin
        Row.Init();
        Row."Entry No." := EntryNo;
        Row.Bucket := NewBucket;
        Row.Insert();
    end;

    [Test]
    procedure SubPageView_FiltersThePartToTheMatchingRowsOnly()
    // THE SUBJECT. Four rows, two matching the view. Walking the part with Next() counts what
    // it actually shows.
    var
        Host: TestPage "SPV Host";
    begin
        Seed();

        Host.OpenEdit();
        Host.GoToKey(1);

        // A BOUNDED WALK, not a count to a total. An editable ListPart shows a trailing blank
        // new row, so counting every row the part yields measures 2 + 1 rather than 2 -- the
        // first version of this arm did exactly that and read the blank row's empty Bucket.
        // The sibling SubPageLink test (TestPagePartLinkFilterGroup.al) walks the same way.
        Assert.IsTrue(Host.FilteredPart.First(), 'the filtered part has a first row');
        Assert.AreEqual('KEEP', Host.FilteredPart.Bucket.Value(), 'the first row the view selects is a KEEP row');
        Assert.AreEqual('1', Host.FilteredPart."Entry No.".Value(), 'the first row the view selects is entry 1');

        Assert.IsTrue(Host.FilteredPart.Next(), 'the filtered part has a second row');
        Assert.AreEqual('KEEP', Host.FilteredPart.Bucket.Value(), 'the second row the view selects is a KEEP row');
        Assert.AreEqual('3', Host.FilteredPart."Entry No.".Value(), 'the second row the view selects is entry 3 -- entry 2 is a DROP row the view excludes');

        Host.Close();
    end;

    [Test]
    procedure PartWithoutSubPageView_ShowsEveryRow()
    // The control, on the SAME host and the same four rows. If this showed 2, the arm above
    // would be measuring something other than the view -- an empty table, or a part that shows
    // nothing. It is what makes a "4 vs 2" result attributable to the view.
    var
        Host: TestPage "SPV Host";
    begin
        Seed();

        Host.OpenEdit();
        Host.GoToKey(1);

        // Same bounded walk. Entry 2 is the discriminator: the view would have excluded it, and
        // this part has no view, so reaching it proves the rows are there to be filtered.
        Assert.IsTrue(Host.OpenPart.First(), 'the open part has a first row');
        Assert.AreEqual('1', Host.OpenPart."Entry No.".Value(), 'the open part starts at entry 1');

        Assert.IsTrue(Host.OpenPart.Next(), 'the open part has a second row');
        Assert.AreEqual(
            '2', Host.OpenPart."Entry No.".Value(),
            'the open part shows entry 2, a DROP row -- so the excluded rows exist and the other arm is measuring the view rather than an empty table');

        Host.Close();
    end;
    [Test]
    procedure SubPageView_FilterLandsInFilterGroup2()
    // WHICH GROUP the view's filter lands in. Distinct from the arms above, which assert the
    // rows shown and would pass whatever group held the filter.
    //
    // Worth its own arm because the three sibling properties do NOT agree, and assuming they do
    // has already been wrong once: an action's RunPageLink lands in group 0 (corpus codeunit
    // 60941), a part's SubPageLink in group 4 (TestPagePartLinkFilterGroup.al). BC's own
    // NavForm.ApplySourceTableView sets ALFilterGroup = 2 around a view's TableFilters, so 2 is
    // the expected answer here -- but that is read off BC's IL, and this arm is what turns it
    // into a service-tier verdict.
    //
    // All three groups in ONE assertion: asserting them separately stops at the first failure
    // and cannot say which group actually holds the filter, which is the question.
    var
        Host: TestPage "SPV Host";
        Probe: Codeunit "SPV Probe";
    begin
        Seed();

        Host.OpenEdit();
        Host.GoToKey(1);

        Assert.IsTrue(Probe.WasOpened(), 'the filtered part must have opened, or the groups below mean nothing');
        Assert.AreEqual(
            'g0=|g2=KEEP|g4=', Probe.Groups(),
            'A part SubPageView''s filter lands in FilterGroup(2) -- not group 0 and not the Link group 4 a SubPageLink uses.');

        Host.Close();
    end;
}
