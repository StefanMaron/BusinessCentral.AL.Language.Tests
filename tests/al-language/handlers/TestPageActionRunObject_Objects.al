// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPARO Row (60450), TPARO Card Target (60451), TPARO Dialog Target (60452),
//                TPARO Host (60453), TPARO Log (60454)
//
// Fixtures for the "an action's RunObject opens its target" suite.
//
// The host page carries four actions that differ only in how they are declared, so a test can
// tell the declarations apart rather than just observing "something opened":
//   RunCardOnRec  - RunObject = Page (Card),           RunPageOnRec = true
//   RunDialogOnRec- RunObject = Page (StandardDialog), RunPageOnRec = true
//   HasTrigger    - an ordinary OnAction trigger, no RunObject at all
//   RunCardOnRec_Promoted - an actionref to RunCardOnRec, the standard promotion shape
//
// The two RunObject targets differ ONLY in PageType, because that is what decides whether the
// platform opens the target modally: a StandardDialog is shown as a dialog, an ordinary Card
// is not. Two targets are needed to state that as a testable claim instead of an assumption.

table 60450 "TPARO Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// Separate from "TPARO Row" on purpose: a handler runs WHILE the host page is open, and
// writing into the host's own source table mid-invoke would move the host's rowset under it.
table 60454 "TPARO Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry"; Code[20]) { }
        field(2; Detail; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry") { Clustered = true; }
    }
}

page 60451 "TPARO Card Target"
{
    PageType = Card;
    SourceTable = "TPARO Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
            field(Descr; Rec.Descr)
            {
                ApplicationArea = All;
            }
        }
    }
}

page 60452 "TPARO Dialog Target"
{
    PageType = StandardDialog;
    SourceTable = "TPARO Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
            field(Descr; Rec.Descr)
            {
                ApplicationArea = All;
            }
        }
    }
}

page 60453 "TPARO Host"
{
    PageType = List;
    SourceTable = "TPARO Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunCardOnRec)
            {
                ApplicationArea = All;
                Caption = 'Run Card On Rec';
                RunObject = Page "TPARO Card Target";
                RunPageOnRec = true;
            }

            action(RunDialogOnRec)
            {
                ApplicationArea = All;
                Caption = 'Run Dialog On Rec';
                RunObject = Page "TPARO Dialog Target";
                RunPageOnRec = true;
            }

            action(HasTrigger)
            {
                ApplicationArea = All;
                Caption = 'Has Trigger';

                trigger OnAction()
                var
                    Log: Record "TPARO Log";
                begin
                    Log.Init();
                    Log.Entry := 'TRIGGER';
                    Log.Detail := Rec."No.";
                    if not Log.Insert() then
                        Log.Modify();
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(RunCardOnRec_Promoted; RunCardOnRec)
                {
                }
            }
        }
    }
}

// #172 investigation. The List host above produced NOTHING on all 8 BC legs -- the action
// invoked, nothing opened, nothing raised. BC's own client has exactly two silent no-op paths
// in ActionControl.Invoke (`if (!Enabled) return null;` and a null LogicalAction), so the
// question is which construction reaches one of them. Microsoft's own Tests-ERM invokes this
// same AL shape with a [PageHandler] bound (page 138 "Purchase Invoice", a DOCUMENT page, with
// the action inside a group under area(Navigation)), so at least one construction does open.
// This host varies the two things that differ from Microsoft's, in one run.
page 60456 "TPARO Card Host"
{
    PageType = Card;
    SourceTable = "TPARO Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
            field(Descr; Rec.Descr)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunCardFromProcessing)
            {
                ApplicationArea = All;
                Caption = 'Run Card From Processing';
                RunObject = Page "TPARO Card Target";
                RunPageOnRec = true;
            }
        }

        area(Navigation)
        {
            group(NavGroup)
            {
                Caption = 'Nav Group';

                action(RunCardFromNavigationGroup)
                {
                    ApplicationArea = All;
                    Caption = 'Run Card From Navigation Group';
                    RunObject = Page "TPARO Card Target";
                    RunPageOnRec = true;
                }
            }
        }
    }
}
