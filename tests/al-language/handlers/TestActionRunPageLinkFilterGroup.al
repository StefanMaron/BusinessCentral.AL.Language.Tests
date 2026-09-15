// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: ARLG Row (60978), ARLG Host (60984), ARLG Target (60985),
//                ARLG Probe (60939), Assert (60021)
//
/// <summary>
/// Pins WHICH filter group an ACTION's RunPageLink filters land in on the opened page's Rec.
///
/// This is the sibling of TestPagePartLinkFilterGroup.al, which pins the same question for a
/// part's SubPageLink (group 4, "Link"). Nothing upstream covers the action/RunPageLink side:
/// no corpus file mentions RunPageLink and FilterGroup together.
///
/// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4160, which measures the
/// runner applying these filters in whatever group is current (0) and cites BC's own client
/// (ApplicationActionFilterContext -> NavFilterHelper.AddFilter, forwarding
/// filterDefinition.FilterGroup) for the claim that BC uses the group the metadata declares.
/// That issue says plainly it has NOT checked which group the compiler writes on
/// RunFormLink.TableFilters. These arms are what answer it, in whichever direction.
///
/// THE PROBE READS THREE GROUPS, and that is what makes a failure attributable rather than
/// merely red. The opened page records GetFilter("Code") under groups 0, 2 and 4, so the arms
/// below distinguish:
///   - the link landing in 4 (the SubPageLink group, which is what #4160 expects),
///   - the link landing in 0 (what the runner does today),
///   - the link landing in 2, or nowhere at all.
/// A single "is it in group 4" assertion could not tell the last three apart.
/// </summary>

table 60978 "ARLG Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Payload; Text[20]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 60939 "ARLG Probe"
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

    procedure Group0(): Text
    begin
        exit(G0);
    end;

    procedure Group2(): Text
    begin
        exit(G2);
    end;

    procedure Group4(): Text
    begin
        exit(G4);
    end;
}

page 60985 "ARLG Target"
{
    PageType = List;
    SourceTable = "ARLG Row";
    ApplicationArea = All;
    Caption = 'ARLG Target';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    // Read the filter the action's RunPageLink left, in each candidate group, and hand all
    // three to the probe. Reading them here rather than asserting here keeps the page a
    // fixture: the arms decide what the values mean.
    trigger OnOpenPage()
    var
        Probe: Codeunit "ARLG Probe";
        F0: Text;
        F2: Text;
        F4: Text;
    begin
        Rec.FilterGroup(0);
        F0 := Rec.GetFilter("Code");
        Rec.FilterGroup(2);
        F2 := Rec.GetFilter("Code");
        Rec.FilterGroup(4);
        F4 := Rec.GetFilter("Code");
        Rec.FilterGroup(0);
        Probe.Record(F0, F2, F4);
    end;
}

page 60984 "ARLG Host"
{
    PageType = Card;
    SourceTable = "ARLG Row";
    ApplicationArea = All;
    Caption = 'ARLG Host';

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenTarget)
            {
                ApplicationArea = All;
                Caption = 'Open Target';
                RunObject = page "ARLG Target";
                RunPageLink = "Code" = field("Code");
            }
        }
    }
}

codeunit 60941 "ARLG Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "ARLG Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Code" := 'AAA';
        Row.Payload := 'first';
        Row.Insert();
        Row.Init();
        Row."Code" := 'BBB';
        Row.Payload := 'second';
        Row.Insert();
    end;

    local procedure InvokeTheAction(HostCode: Code[20])
    var
        Probe: Codeunit "ARLG Probe";
        Host: TestPage "ARLG Host";
    begin
        Seed();
        Probe.Reset();

        Host.OpenEdit();
        Host.GoToKey(HostCode);
        Host.OpenTarget.Invoke();
        Host.Close();
    end;

    [Test]
    [HandlerFunctions('ArlgTargetHandler')]
    procedure RunPageLink_FilterLandsInGroup4_NotGroup0()
    // THE SUBJECT. The three groups are read in one open, so this arm says not just "is it in
    // 4" but "which of the three has it" -- and the two companion assertions are what rule out
    // the runner's current answer (group 0) and the remaining candidate (group 2).
    var
        Probe: Codeunit "ARLG Probe";
    begin
        InvokeTheAction('AAA');

        Assert.IsTrue(Probe.WasOpened(), 'The action must have opened the target page, or the filter assertions below mean nothing.');
        Assert.AreEqual('AAA', Probe.Group4(), 'An action''s RunPageLink filter must land in FilterGroup(4), the Link group.');
        Assert.AreEqual('', Probe.Group0(), 'The RunPageLink filter must NOT land in FilterGroup(0).');
        Assert.AreEqual('', Probe.Group2(), 'The RunPageLink filter must NOT land in FilterGroup(2).');
    end;

    [Test]
    [HandlerFunctions('ArlgTargetHandler')]
    procedure RunPageLink_FilterFollowsTheHostRow()
    // The link is a FIELD reference, so a different host row must produce a different filter.
    // Without this, the arm above would also pass against an implementation that hardcoded the
    // first row's value, or that applied a constant.
    var
        Probe: Codeunit "ARLG Probe";
    begin
        InvokeTheAction('BBB');

        Assert.IsTrue(Probe.WasOpened(), 'The action must have opened the target page.');
        Assert.AreEqual('BBB', Probe.Group4(), 'The RunPageLink filter must carry the host row''s own Code, not a fixed value.');
        Assert.AreEqual('', Probe.Group0(), 'The RunPageLink filter must NOT land in FilterGroup(0) for this row either.');
    end;

    [PageHandler]
    procedure ArlgTargetHandler(var TargetPage: TestPage "ARLG Target")
    begin
        // The page's own OnOpenPage has already recorded the three filters by the time this
        // runs. Closing is all this handler needs to do.
        TargetPage.Close();
    end;
}
