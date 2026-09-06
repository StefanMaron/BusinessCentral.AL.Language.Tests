// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPARONH Row (60280), TPARONH Card Target (60281),
//                TPARONH Logging Target (60282), TPARONH Host (60283), TPARONH Log (60284)
//
// Fixtures for "what does a RunObject action do when no handler is bound". The answer these
// were built to find is recorded in TestPageActionRunObjectNoHandler_Tests.al: the target page
// opens unattended, and AL is never told.
//
// These duplicate the shape of the TPARO fixtures rather than reusing them, on purpose. This
// change sat open while that question was unsettled, and the corpus gate that matters here
// compares the object ids a pull request INTRODUCES against every other open pull request.
// Sharing the TPARO objects would have meant claiming their ids too, which collides with the
// change that introduces them and blocks both. A self-contained fixture set also means these
// tests keep compiling and keep measuring exactly what they measured on the day the answer was
// recorded, whatever happens to the TPARO suite.

table 60280 "TPARONH Row"
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

// Separate from "TPARONH Row": a handler runs WHILE the host page is open, and writing into
// the host's own source table mid-invoke would move the host's rowset under it.
table 60284 "TPARONH Log"
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

page 60281 "TPARONH Card Target"
{
    PageType = Card;
    SourceTable = "TPARONH Row";
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

// A second target, identical to the one above except that it records its own OnOpenPage. The
// Card Target is kept clean so the refusal controls cannot be disturbed by a write happening
// before BC decides to refuse; this one exists so a test can answer the separate question "did
// the page open at all", without needing a handler to observe it. A handler only runs when it
// is bound, so a handler cannot answer that question for an invoke with nothing bound. It is
// how the tests establish that an unattended RunObject target really does open: this trigger
// runs, on the host page's current row.
page 60282 "TPARONH Logging Target"
{
    PageType = Card;
    SourceTable = "TPARONH Row";
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

    trigger OnOpenPage()
    var
        Log: Record "TPARONH Log";
    begin
        Log.Init();
        Log.Entry := 'OPENED';
        Log.Detail := Rec.Descr;
        if not Log.Insert() then
            Log.Modify();
    end;
}

page 60283 "TPARONH Host"
{
    PageType = List;
    SourceTable = "TPARONH Row";
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
            // The subject: the effect is declared, no AL runs.
            action(RunCardOnRec)
            {
                ApplicationArea = All;
                Caption = 'Run Card On Rec';
                RunObject = Page "TPARONH Card Target";
                RunPageOnRec = true;
            }

            // The diagnostic: same declaration as RunCardOnRec, aimed at the target that
            // records its own opening, so a test can ask whether the page opened rather than
            // only whether an error was raised.
            action(RunLoggingCardOnRec)
            {
                ApplicationArea = All;
                Caption = 'Run Logging Card On Rec';
                RunObject = Page "TPARONH Logging Target";
                RunPageOnRec = true;
            }

            // The control: the SAME target page, opened on the SAME row, reached through the
            // SAME kind of invoke -- but by AL in an OnAction trigger rather than by a
            // RunObject declaration. This is the only difference between the two actions, so a
            // run in which one is refused and the other is not has isolated the declaration.
            action(RunCardViaTrigger)
            {
                ApplicationArea = All;
                Caption = 'Run Card Via Trigger';

                trigger OnAction()
                begin
                    Page.Run(Page::"TPARONH Card Target", Rec);
                end;
            }
        }
    }
}
