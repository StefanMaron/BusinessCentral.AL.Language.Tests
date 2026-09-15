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
    begin
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
        Seen: Integer;
    begin
        Seed();

        Host.OpenEdit();
        Host.GoToKey(1);

        Seen := 0;
        if Host.FilteredPart.First() then
            repeat
                Seen := Seen + 1;
                Assert.AreEqual(
                    'KEEP', Host.FilteredPart.Bucket.Value(),
                    'Every row the part shows must match its SubPageView, so no DROP row may appear.');
            until not Host.FilteredPart.Next();

        Assert.AreEqual(2, Seen, 'The part must show exactly the two rows its SubPageView selects.');
        Host.Close();
    end;

    [Test]
    procedure PartWithoutSubPageView_ShowsEveryRow()
    // The control, on the SAME host and the same four rows. If this showed 2, the arm above
    // would be measuring something other than the view -- an empty table, or a part that shows
    // nothing. It is what makes a "4 vs 2" result attributable to the view.
    var
        Host: TestPage "SPV Host";
        Seen: Integer;
    begin
        Seed();

        Host.OpenEdit();
        Host.GoToKey(1);

        Seen := 0;
        if Host.OpenPart.First() then
            repeat
                Seen := Seen + 1;
            until not Host.OpenPart.Next();

        Assert.AreEqual(4, Seen, 'A part with no SubPageView must show every row in its source table.');
        Host.Close();
    end;
}
