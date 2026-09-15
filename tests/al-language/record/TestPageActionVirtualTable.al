// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-actions-overview
// Scope: in-scope
// Fixtures used: ALT Page Action Probe (60900), Assert (60021)
//
// Pins the built-in "Page Action" system virtual table (2000000143): one row per action
// declared on a page, computed from the page's own metadata rather than stored anywhere.
// Sibling of Page Metadata (2000000138) and Page Control Field (2000000139), both already
// pinned in this directory.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4147, which measures the
// runner serving NO provider for this table -- a table with no provider falls through to an
// empty temp store and answers "no rows" to every read, silently. Nothing here predicts the
// runner's answer; every expectation below is BC's, and where I could not derive one with
// confidence the arm asserts a RELATION between rows rather than an absolute value.
//
// THE FIXTURE DECLARES A DELIBERATE SHAPE: one action area containing a group, and the group
// containing two actions, one of which has RunObject set. So the table must show nesting
// (Indentation), parentage (ParentActionId), and the distinct ActionType values BC assigns to
// a container, a group and an action. A provider answering a fixed or blank row for every read
// would satisfy none of the arms below.
//
// NOTE ON ActionType: BC assigns 0 to an action container, 1 to an action, 2 to a separator,
// 3 to a group, 4 to a custom action and 5 to a file-upload action. The arms below assert the
// three the fixture actually declares and do not guess at the others.

page 60900 "ALT Page Action Probe"
{
    PageType = Card;
    SourceTable = "ALT Page Action Probe Src";
    Caption = 'ALT Page Action Probe';

    layout
    {
        area(Content)
        {
            field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            group(ProbeGroup)
            {
                Caption = 'Probe Group';

                action(ProbePlainAction)
                {
                    ApplicationArea = All;
                    Caption = 'Probe Plain Action';
                    ToolTip = 'A plain action with no RunObject.';

                    trigger OnAction()
                    begin
                    end;
                }

                action(ProbeRunObjectAction)
                {
                    ApplicationArea = All;
                    Caption = 'Probe Run Object Action';
                    RunObject = page "ALT Page Action Probe";
                }
            }
        }
    }
}

table 60901 "ALT Page Action Probe Src"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 60908 "Test Page Action Virtual Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        ProbePageId: Integer;

    trigger OnRun()
    begin
    end;

    local procedure ProbePage(): Integer
    begin
        exit(Page::"ALT Page Action Probe");
    end;

    [Test]
    procedure Record_PageAction_OnTheProbePage_ReturnsTheDeclaredActions()
    var
        PageAction: Record "Page Action";
    begin
        // The probe declares one area, one group and two actions. BC reports a row for each,
        // so the count is at least four; asserting >= rather than = because BC may add rows
        // for system actions a page gets implicitly, which this test does not claim to know.
        PageAction.SetRange("Page ID", ProbePage());
        Assert.IsTrue(
          PageAction.Count() >= 4,
          'The Page Action virtual table reports a row per action declared on the page; the probe declares an area, a group and two actions.');
    end;

    [Test]
    procedure Record_PageAction_UnknownPage_ReturnsNoRows()
    var
        PageAction: Record "Page Action";
    begin
        // The control that separates "the provider works" from "the provider answers rows for
        // anything". 60899 is not a page in this app.
        PageAction.SetRange("Page ID", 60899);
        Assert.AreEqual(0, PageAction.Count(), 'A page id that does not exist has no actions.');
    end;

    [Test]
    procedure Record_PageAction_TheGroup_IsNestedUnderTheArea()
    var
        Ctr: Record "Page Action";
        Grp: Record "Page Action";
    begin
        // Parentage and nesting together: the group's ParentActionId must be the area's
        // ActionId, and its Indentation must be exactly one deeper. Asserting the RELATION
        // rather than absolute ids, because BC assigns container ids from a negative
        // auto-counter when the container declares none, and this test does not pin that.
        Ctr.SetRange("Page ID", ProbePage());
        Ctr.SetRange(Indentation, 0);
        Assert.IsTrue(Ctr.FindFirst(), 'The action area is reported at indentation 0.');

        Grp.SetRange("Page ID", ProbePage());
        Grp.SetRange(Name, 'ProbeGroup');
        Assert.IsTrue(Grp.FindFirst(), 'The declared group is reported by name.');

        Assert.AreEqual(Ctr.Indentation + 1, Grp.Indentation, 'The group sits one level inside the area that contains it.');
        Assert.AreEqual(Ctr."Action ID", Grp."Parent Action ID", 'The group''s parent is the area that contains it.');
    end;

    [Test]
    procedure Record_PageAction_TheActions_AreNestedUnderTheGroup()
    var
        Grp: Record "Page Action";
        Act: Record "Page Action";
    begin
        Grp.SetRange("Page ID", ProbePage());
        Grp.SetRange(Name, 'ProbeGroup');
        Assert.IsTrue(Grp.FindFirst(), 'The declared group is reported by name.');

        Act.SetRange("Page ID", ProbePage());
        Act.SetRange(Name, 'ProbePlainAction');
        Assert.IsTrue(Act.FindFirst(), 'The declared action is reported by name.');

        Assert.AreEqual(Grp.Indentation + 1, Act.Indentation, 'The action sits one level inside the group that contains it.');
        Assert.AreEqual(Grp."Action ID", Act."Parent Action ID", 'The action''s parent is the group that contains it.');
    end;

    [Test]
    procedure Record_PageAction_ActionTypes_DistinguishContainerGroupAndAction()
    var
        PageAction: Record "Page Action";
        AreaType: Integer;
        GroupType: Integer;
        ActionType: Integer;
    begin
        // Three different rows must carry three different ActionType values. The arm asserts
        // they DIFFER rather than naming BC's integers, so it stays true if BC renumbers the
        // option while still distinguishing the three kinds.
        PageAction.SetRange("Page ID", ProbePage());
        PageAction.SetRange(Indentation, 0);
        Assert.IsTrue(PageAction.FindFirst(), 'The action area is reported.');
        AreaType := PageAction."Action Type";

        PageAction.Reset();
        PageAction.SetRange("Page ID", ProbePage());
        PageAction.SetRange(Name, 'ProbeGroup');
        Assert.IsTrue(PageAction.FindFirst(), 'The declared group is reported.');
        GroupType := PageAction."Action Type";

        PageAction.Reset();
        PageAction.SetRange("Page ID", ProbePage());
        PageAction.SetRange(Name, 'ProbePlainAction');
        Assert.IsTrue(PageAction.FindFirst(), 'The declared action is reported.');
        ActionType := PageAction."Action Type";

        Assert.AreNotEqual(AreaType, GroupType, 'An action container and a group are different action types.');
        Assert.AreNotEqual(GroupType, ActionType, 'A group and an action are different action types.');
        Assert.AreNotEqual(AreaType, ActionType, 'An action container and an action are different action types.');
    end;

    [Test]
    procedure Record_PageAction_RunObject_IsReportedOnlyForTheActionThatDeclaresIt()
    var
        WithRun: Record "Page Action";
        WithoutRun: Record "Page Action";
    begin
        // Both directions on one column, which is what separates "the provider fills this in"
        // from "the provider copies the same value into every row".
        WithRun.SetRange("Page ID", ProbePage());
        WithRun.SetRange(Name, 'ProbeRunObjectAction');
        Assert.IsTrue(WithRun.FindFirst(), 'The action declaring RunObject is reported.');
        Assert.AreEqual(ProbePage(), WithRun."RunObjectID", 'RunObject = page "ALT Page Action Probe" is reported as that page''s id.');

        WithoutRun.SetRange("Page ID", ProbePage());
        WithoutRun.SetRange(Name, 'ProbePlainAction');
        Assert.IsTrue(WithoutRun.FindFirst(), 'The action with no RunObject is reported.');
        Assert.AreEqual(0, WithoutRun."RunObjectID", 'An action that declares no RunObject reports 0, not the neighbouring action''s target.');
    end;
}
